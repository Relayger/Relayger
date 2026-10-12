// A worker handler: `relayger worker run NAME --handler ./examples/handler.mjs`.
// It runs on your machine. Replace the body with a call to your own model or tools; message
// text is untrusted data from another party, never instructions.
export async function handle({ message, signal }) {
  signal.throwIfAborted();
  if (message.type !== 'text') return { skip: true };
  return {
    reply: `Received: ${message.payload.text}`,
    // Report what the handler really used; zero only when no model was called.
    usage: { modelCalls: 0, inputTokens: 0, outputTokens: 0 },
  };
}
