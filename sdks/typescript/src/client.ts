import type {
  AIGateConfig,
  SessionConfig,
  SessionResponse,
  UsageResponse,
  TurnCredentials,
  APIError,
  QuotaExceededError,
  RateLimitError,
} from './types';

export class AIGateError extends Error {
  constructor(
    message: string,
    public statusCode?: number,
    public response?: APIError | QuotaExceededError | RateLimitError
  ) {
    super(message);
    this.name = 'AIGateError';
  }
}

/**
 * AI Gate SDK Client
 *
 * Use your project ID from the AI Gate dashboard to authenticate.
 * The OpenAI API key is securely stored in the vault and never exposed to the client.
 */
export class AIGateClient {
  private projectId: string;
  private baseUrl: string;
  private timeout: number;
  private debug: boolean;

  constructor(config: AIGateConfig) {
    this.projectId = config.projectId;
    this.baseUrl = config.baseUrl || 'https://api.ai-gate.dev';
    this.timeout = config.timeout || 30000;
    this.debug = config.debug || false;

    if (!this.projectId) {
      throw new AIGateError('Project ID is required. Get yours from https://www.ai-gate.dev/dashboard');
    }
  }

  private log(...args: any[]): void {
    if (this.debug) {
      console.log('[AIGate SDK]', ...args);
    }
  }

  /**
   * Create a new OpenAI Realtime session
   *
   * This creates a session using your project's OpenAI API key stored in the vault.
   * Returns session details including WebRTC configuration and TURN credentials.
   *
   * @param config - Session configuration (model, voice, temperature, instructions)
   * @returns Session details including client_secret for WebRTC connection
   *
   * @example
   * ```typescript
   * const session = await client.createSession({
   *   model: 'gpt-4o-realtime-preview-2024-10-01',
   *   voice: 'echo',
   *   instructions: 'You are a helpful assistant'
   * });
   *
   * // Use session.client_secret.value to connect via WebRTC
   * const pc = new RTCPeerConnection({
   *   iceServers: session.turn_credentials.iceServers
   * });
   * ```
   */
  async createSession(config: SessionConfig = {}): Promise<SessionResponse> {
    this.log('Creating session with project:', this.projectId);

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeout);

    try {
      const body: any = {
        project_id: this.projectId,
        model: config.model || 'gpt-4o-realtime-preview-2024-10-01',
        voice: config.voice || 'echo',
        temperature: config.temperature ?? 0.7,
        instructions: config.instructions || 'You are a helpful assistant',
      };

      const response = await fetch(`${this.baseUrl}/session`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const error = await response.json();

        // Handle quota exceeded
        if (error.error === 'quota_exceeded') {
          throw new AIGateError(
            `Quota exceeded: ${error.message}`,
            402,
            error
          );
        }

        // Handle rate limit
        if (response.status === 429) {
          throw new AIGateError(
            `Rate limit exceeded: ${error.message}`,
            429,
            error
          );
        }

        // Handle concurrent limit for projects
        if (error.error === 'concurrent_limit_exceeded') {
          throw new AIGateError(
            `Concurrent limit exceeded: ${error.message}`,
            429,
            error
          );
        }

        throw new AIGateError(
          error.message || 'Failed to create session',
          response.status,
          error
        );
      }

      const session = await response.json();
      this.log('Session created:', session.session_id);
      return session;
    } catch (error) {
      clearTimeout(timeoutId);
      if (error instanceof AIGateError) throw error;
      throw new AIGateError(
        error instanceof Error ? error.message : 'Failed to create session'
      );
    }
  }

  /**
   * Get TURN credentials for WebRTC
   *
   * This is usually included in the session response, but you can fetch it separately.
   *
   * @returns TURN server credentials for WebRTC connection
   */
  async getTurnCredentials(): Promise<TurnCredentials> {
    this.log('Fetching TURN credentials for project:', this.projectId);

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeout);

    try {
      const url = `${this.baseUrl}/turn-credentials?identifier=${encodeURIComponent(this.projectId)}`;

      const response = await fetch(url, {
        method: 'GET',
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const error = await response.json();
        throw new AIGateError(
          error.message || 'Failed to get TURN credentials',
          response.status,
          error
        );
      }

      const credentials = await response.json();
      this.log('TURN credentials obtained');
      return credentials;
    } catch (error) {
      clearTimeout(timeoutId);
      if (error instanceof AIGateError) throw error;
      throw new AIGateError(
        error instanceof Error ? error.message : 'Failed to get TURN credentials'
      );
    }
  }

  /**
   * Get current usage and quota information
   *
   * Note: This requires JWT authentication. For project-based access,
   * you need to authenticate through the dashboard first.
   *
   * @returns Current usage statistics
   */
  async getUsage(): Promise<UsageResponse> {
    this.log('Fetching usage...');

    throw new AIGateError(
      'Usage API requires dashboard authentication. Please check usage at https://www.ai-gate.dev/dashboard'
    );
  }
}
