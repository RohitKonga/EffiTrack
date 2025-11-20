const fetch = (...args) => import('node-fetch').then(({ default: fetch }) => fetch(...args));
const { GoogleAuth } = require('google-auth-library');

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const MAX_CONCURRENT_REQUESTS = 20;

let authClient;
let warnedMissingCredentials = false;

const getAuthClient = async () => {
  if (authClient) return authClient;

  const { FCM_PROJECT_ID, FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY } = process.env;
  if (!FCM_PROJECT_ID || !FCM_CLIENT_EMAIL || !FCM_PRIVATE_KEY) {
    if (!warnedMissingCredentials && process.env.NODE_ENV !== 'test') {
      console.warn(
        '[NotificationService] Missing FCM credentials. Set FCM_PROJECT_ID, FCM_CLIENT_EMAIL, and FCM_PRIVATE_KEY.',
      );
      warnedMissingCredentials = true;
    }
    return null;
  }

  const normalizedKey = FCM_PRIVATE_KEY.replace(/\\n/g, '\n');
  const googleAuth = new GoogleAuth({
    credentials: {
      client_email: FCM_CLIENT_EMAIL,
      private_key: normalizedKey,
    },
    projectId: FCM_PROJECT_ID,
    scopes: [FCM_SCOPE],
  });

  authClient = await googleAuth.getClient();
  return authClient;
};

const getAccessToken = async () => {
  const client = await getAuthClient();
  if (!client) return null;

  const tokenResponse = await client.getAccessToken();
  if (typeof tokenResponse === 'string') {
    return tokenResponse;
  }
  return tokenResponse?.token ?? null;
};

const sendToTokens = async (tokens, notification, data) => {
  const { FCM_PROJECT_ID } = process.env;
  const accessToken = await getAccessToken();

  if (!FCM_PROJECT_ID || !accessToken) {
    return;
  }

  const endpoint = `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`;
  const queue = [...tokens];
  const workerCount = Math.min(MAX_CONCURRENT_REQUESTS, queue.length || 1);

  const workers = Array.from({ length: workerCount }).map(async () => {
    while (queue.length) {
      const token = queue.shift();
      if (!token) continue;

      try {
        const response = await fetch(endpoint, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            message: {
              token,
              notification,
              data,
            },
          }),
        });

        if (!response.ok) {
          const body = await response.text();
          console.error('[NotificationService] Failed to send FCM message:', body);
        }
      } catch (error) {
        console.error('[NotificationService] FCM request error:', error.message);
      }
    }
  });

  await Promise.all(workers);
};

exports.sendAnnouncementNotification = async (tokens = [], payload = {}) => {
  if (!Array.isArray(tokens) || tokens.length === 0) return;

  const uniqueTokens = [...new Set(tokens.filter(Boolean))];
  if (!uniqueTokens.length) return;

  const notification = {
    title: payload.title || 'New Announcement',
    body: payload.message
      ? `${payload.senderName ? `${payload.senderName}: ` : ''}${payload.message}`
      : 'You have a new announcement.',
  };

  const data = {
    type: 'announcement',
    announcementTitle: payload.title ?? '',
    announcementMessage: payload.message ?? '',
    senderName: payload.senderName ?? '',
    targetDepartment: payload.department ?? '',
    createdAt: payload.createdAt ?? new Date().toISOString(),
  };

  await sendToTokens(uniqueTokens, notification, data);
};

