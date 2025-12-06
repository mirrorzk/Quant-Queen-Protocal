
type Level = 'debug' | 'info' | 'warn' | 'error'

export function isTestDomain() {
  if (typeof window === 'undefined') return false;
  const host = window.location.hostname.toLowerCase();

  return (
    host.includes("website") ||
    host.includes("localhost")
  );
}
function output(level: Level, ...args: unknown[]) {
  const isProd = !isTestDomain()

  if (isProd) return 
  const method = level === 'debug' ? 'log' : level
  console[method](`[${level.toUpperCase()}]`, ...args)
}

export const log = {
  debug: (...a: unknown[]) => output('debug', ...a),
  info:  (...a: unknown[]) => output('info', ...a),
  warn:  (...a: unknown[]) => output('warn', ...a),
  error: (...a: unknown[]) => output('error', ...a),
}
