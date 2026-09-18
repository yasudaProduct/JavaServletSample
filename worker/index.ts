/**
 * Cloudflare Workers のエントリポイント。
 *
 * Cloudflare の Workers 自体は Java を実行できません。そのため Tomcat は
 * 「Cloudflare Containers」上のコンテナとして動かし、この Worker は
 * 受け取ったリクエストをそのコンテナへそのまま転送する入口として動きます。
 *
 *     ブラウザ → Worker (このファイル) → Container (Tomcat 9 + ROOT)
 *
 * コンテナの中身は docker/cloudflare/Dockerfile、
 * どのインスタンスサイズで動かすかは wrangler.jsonc を参照してください。
 */
import { Container, getContainer } from '@cloudflare/containers';

/** Tomcat が listen しているポート (docker/cloudflare/Dockerfile の EXPOSE と合わせる) */
const TOMCAT_PORT = 8080;

/**
 * JVM + Tomcat の起動を待つ上限 (ミリ秒)。
 *
 * ライブラリの既定は 20 秒ですが、小さいインスタンスだと Tomcat の起動が
 * それを超えることがあります。超えると 500 が返ってしまうため延ばしています。
 */
const STARTUP_TIMEOUT_MS = 60_000;

interface Env {
  TOMCAT: DurableObjectNamespace<TomcatContainer>;
}

export class TomcatContainer extends Container<Env> {
  defaultPort = TOMCAT_PORT;
  requiredPorts = [TOMCAT_PORT];

  /**
   * この時間だけリクエストが無ければコンテナを停止する。
   * 停止中は課金されない代わりに、次のアクセスで起動待ち
   * (コールドスタート) が発生します。短くすると安く、長くすると速くなります。
   */
  sleepAfter = '15m';

  /** Bootstrap 等も同梱していてアプリは自己完結しているので、外向き通信は塞ぐ */
  enableInternet = false;

  envVars = { TZ: 'Asia/Tokyo' };

  /**
   * 既定のポート待ち時間 (20 秒) では JVM の起動に間に合わないことがあるため、
   * 起動していないときだけ STARTUP_TIMEOUT_MS まで待ってから転送する。
   * 起動済みの場合はこの if に入らないので、通常のリクエストは素通りします。
   */
  override async fetch(request: Request): Promise<Response> {
    const state = await this.getState();
    if (!this.ctx.container?.running || state.status !== 'healthy') {
      await this.startAndWaitForPorts({
        ports: [TOMCAT_PORT],
        cancellationOptions: { portReadyTimeoutMS: STARTUP_TIMEOUT_MS },
      });
    }
    return super.fetch(request);
  }

  // ログは `npx wrangler tail` またはダッシュボードの Workers Logs で見られます
  override onStart(): void {
    console.log('Tomcat container started');
  }

  override onStop(): void {
    console.log('Tomcat container stopped');
  }

  override onError(error: unknown): void {
    console.error('Tomcat container error:', error);
  }
}

export default {
  async fetch(request, env) {
    // セッションを使うサンプルを想定して、リクエストは 1 つのコンテナに集めます
    // (コンテナが分かれるとログイン状態などが引き継がれないため)。
    // 負荷を分散したくなったら getRandom(env.TOMCAT, 台数) に変更し、
    // wrangler.jsonc の max_instances も合わせて増やしてください。
    return getContainer(env.TOMCAT).fetch(request);
  },
} satisfies ExportedHandler<Env>;
