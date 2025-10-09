/**
 * Tests for AIGateClient
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { AIGateClient, AIGateError } from './client';

// Mock fetch globally
global.fetch = vi.fn();

describe('AIGateClient', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Constructor', () => {
    it('should throw error if projectId is missing', () => {
      expect(() => {
        new AIGateClient({ projectId: '' });
      }).toThrow('Project ID is required');
    });

    it('should initialize with default values', () => {
      const client = new AIGateClient({ projectId: 'test-project' });
      expect(client).toBeDefined();
    });

    it('should accept custom baseUrl and timeout', () => {
      const client = new AIGateClient({
        projectId: 'test-project',
        baseUrl: 'https://custom.api.com',
        timeout: 60000,
        debug: true,
      });
      expect(client).toBeDefined();
    });
  });

  describe('createSession', () => {
    it('should create a session successfully', async () => {
      const mockSession = {
        id: 'sess_123',
        model: 'gpt-4o-realtime-preview-2024-10-01',
        expires_at: Date.now() / 1000 + 3600,
        session_id: 'aigate_session_123',
        metadata: {
          model: 'gpt-4o-realtime-preview-2024-10-01',
          voice: 'echo',
          turn_server: 'cloudflare',
          created_at: new Date().toISOString(),
        },
        turn_credentials: {
          iceServers: [
            { urls: 'stun:stun.cloudflare.com:3478' },
            {
              urls: 'turn:turn.cloudflare.com:3478',
              username: 'test',
              credential: 'test',
            },
          ],
        },
        client_secret: {
          value: 'test-secret',
          expires_at: Date.now() / 1000 + 3600,
        },
      };

      (global.fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => mockSession,
      });

      const client = new AIGateClient({ projectId: 'test-project' });
      const session = await client.createSession();

      expect(session).toEqual(mockSession);
      expect(global.fetch).toHaveBeenCalledWith(
        'https://api.ai-gate.dev/session',
        expect.objectContaining({
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: expect.stringContaining('test-project'),
        })
      );
    });

    it('should handle quota exceeded error', async () => {
      const mockError = {
        error: 'quota_exceeded',
        message: 'Monthly quota exceeded',
        usage: {
          plan: 'free',
          sessionsIncluded: 100,
          sessionsUsed: 100,
          sessionsRemaining: 0,
        },
        upgrade_url: 'https://www.ai-gate.dev/dashboard?upgrade=free',
      };

      (global.fetch as any).mockResolvedValue({
        ok: false,
        status: 402,
        json: async () => mockError,
      });

      const client = new AIGateClient({ projectId: 'test-project' });

      await expect(client.createSession()).rejects.toThrow(AIGateError);
      await expect(client.createSession()).rejects.toThrow('Quota exceeded');
    });

    it('should handle rate limit error', async () => {
      const mockError = {
        error: 'Rate limit exceeded',
        message: 'Too many requests',
        limit: 100,
        window: '15 minutes',
        resetAt: new Date().toISOString(),
      };

      (global.fetch as any).mockResolvedValue({
        ok: false,
        status: 429,
        json: async () => mockError,
      });

      const client = new AIGateClient({ projectId: 'test-project' });

      await expect(client.createSession()).rejects.toThrow(AIGateError);
      await expect(client.createSession()).rejects.toThrow('Rate limit exceeded');
    });

    it('should handle concurrent limit error', async () => {
      const mockError = {
        error: 'concurrent_limit_exceeded',
        message: 'Maximum 5 concurrent sessions',
        current: 5,
        max: 5,
      };

      (global.fetch as any).mockResolvedValue({
        ok: false,
        status: 429,
        json: async () => mockError,
      });

      const client = new AIGateClient({ projectId: 'test-project' });

      await expect(client.createSession()).rejects.toThrow(AIGateError);
      await expect(client.createSession()).rejects.toThrow('Maximum 5 concurrent sessions');
    });

    it('should use custom session configuration', async () => {
      const mockSession = {
        id: 'sess_123',
        model: 'gpt-4o-realtime-preview-2024-10-01',
        expires_at: Date.now() / 1000 + 3600,
        session_id: 'aigate_session_123',
        metadata: {
          model: 'gpt-4o-realtime-preview-2024-10-01',
          voice: 'nova',
          turn_server: 'cloudflare',
          created_at: new Date().toISOString(),
        },
        turn_credentials: {
          iceServers: [],
        },
        client_secret: {
          value: 'test-secret',
          expires_at: Date.now() / 1000 + 3600,
        },
      };

      (global.fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => mockSession,
      });

      const client = new AIGateClient({ projectId: 'test-project' });
      await client.createSession({
        voice: 'nova',
        temperature: 0.9,
        instructions: 'Custom instructions',
      });

      const fetchCall = (global.fetch as any).mock.calls[0];
      const requestBody = JSON.parse(fetchCall[1].body);

      expect(requestBody.voice).toBe('nova');
      expect(requestBody.temperature).toBe(0.9);
      expect(requestBody.instructions).toBe('Custom instructions');
    });
  });

  describe('getTurnCredentials', () => {
    it('should get TURN credentials successfully', async () => {
      const mockCredentials = {
        iceServers: [
          { urls: 'stun:stun.cloudflare.com:3478' },
          {
            urls: 'turn:turn.cloudflare.com:3478',
            username: 'test',
            credential: 'test',
          },
        ],
      };

      (global.fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => mockCredentials,
      });

      const client = new AIGateClient({ projectId: 'test-project' });
      const credentials = await client.getTurnCredentials();

      expect(credentials).toEqual(mockCredentials);
      expect(global.fetch).toHaveBeenCalledWith(
        expect.stringContaining('/turn-credentials?identifier=test-project'),
        expect.objectContaining({ method: 'GET' })
      );
    });

    it('should handle TURN credentials error', async () => {
      (global.fetch as any).mockResolvedValueOnce({
        ok: false,
        status: 500,
        json: async () => ({ error: 'Internal error', message: 'Failed' }),
      });

      const client = new AIGateClient({ projectId: 'test-project' });

      await expect(client.getTurnCredentials()).rejects.toThrow(AIGateError);
    });
  });

  describe('Error handling', () => {
    it('should handle network errors', async () => {
      (global.fetch as any).mockRejectedValueOnce(new Error('Network error'));

      const client = new AIGateClient({ projectId: 'test-project' });

      await expect(client.createSession()).rejects.toThrow('Network error');
    });

    it('should handle AbortController timeout', async () => {
      // Mock fetch to reject after delay
      (global.fetch as any).mockImplementationOnce(
        () => new Promise((_, reject) => {
          setTimeout(() => reject(new Error('Aborted')), 50);
        })
      );

      const client = new AIGateClient({ projectId: 'test-project', timeout: 100 });

      await expect(client.createSession()).rejects.toThrow();
    });
  });

  describe('AIGateError', () => {
    it('should create error with message only', () => {
      const error = new AIGateError('Test error');
      expect(error.message).toBe('Test error');
      expect(error.statusCode).toBeUndefined();
      expect(error.response).toBeUndefined();
    });

    it('should create error with status code', () => {
      const error = new AIGateError('Test error', 400);
      expect(error.message).toBe('Test error');
      expect(error.statusCode).toBe(400);
    });

    it('should create error with response', () => {
      const response = { error: 'test', message: 'Test error' };
      const error = new AIGateError('Test error', 400, response);
      expect(error.response).toEqual(response);
    });
  });
});
