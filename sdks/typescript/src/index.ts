/**
 * AI Gate SDK
 *
 * Official TypeScript/JavaScript SDK for AI Gate - OpenAI Realtime API Proxy
 *
 * @example
 * ```typescript
 * import { AIGateClient } from '@ai-gate/sdk';
 *
 * const client = new AIGateClient({
 *   projectId: 'your-project-id-from-dashboard'
 * });
 *
 * const session = await client.createSession({
 *   model: 'gpt-4o-realtime-preview-2024-10-01',
 *   voice: 'echo',
 *   instructions: 'You are a helpful assistant'
 * });
 *
 * console.log('Session created:', session.id);
 * console.log('Client secret:', session.client_secret.value);
 * ```
 */

export { AIGateClient, AIGateError } from './client';
export type {
  AIGateConfig,
  SessionConfig,
  SessionResponse,
  TurnCredentials,
  UsageResponse,
  QuotaExceededError,
  RateLimitError,
  APIError,
  BillingPlan,
} from './types';
