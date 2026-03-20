export function buildMessagePackage(type, data) {
    return JSON.stringify({ type, data });
}