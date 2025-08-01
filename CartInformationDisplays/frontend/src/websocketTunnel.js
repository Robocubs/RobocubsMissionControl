import { writable } from 'svelte/store';

function createWebsocketTunnel(url) {
  const { subscribe, set, update } = writable({
    socket: null,
    connected: false,
    message: {
      type: null,
      data: "",
    },
  });

  let socket;
  let reconnectTimeout;

  function connect() {
    socket = new WebSocket(url);

    socket.onopen = () => {
        update(state => ({ ...state, connected: true }));
    };

    socket.onmessage = (event) => {
        console.log("Message received:", event.data);
        update(state => ({ ...state, message: JSON.parse(event.data) }));
    };

    socket.onclose = () => {
        update(state => ({ ...state, connected: false }));
            reconnectTimeout = setTimeout(connect, 2000);
    };

    socket.onerror = () => {
        socket?.close();
    };

    set({ socket, connected: false, message: { type: null, data: "" } });
  }

  function sendMessage(message) {
    if (socket && socket.readyState === WebSocket.OPEN) {
        socket.send(message);
    }
  }

  connect();

  return {
    subscribe,
    sendMessage,
    connect,
  };
}

export default createWebsocketTunnel;