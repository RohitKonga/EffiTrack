const fetch = require('node-fetch');

const FCM_ENDPOINT = 'https://fcm.googleapis.com/fcm/send';
const MAX_BATCH_SIZE = 950; // stay below FCM limit of 1000

const chunkArray = (items, chunkSize) => {
  const chunks = [];
  for (let i = 0; i < items.length; i += chunkSize) {
    chunks.push(items.slice(i, i + chunkSize));
  }
  return chunks;
};

const sendBatch = async (tokens, notification, data) => {
  const serverKey = process.env.FCM_SERVER_KEY;
  if (!serverKey) {
    if (process.env.NODE_ENV !== 'test') {
      console.warn('[NotificationService] FCM_SERVER_KEY is not configured.');
    }
    return;
  }

  try {
    const response = await fetch(FCM_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `key=${serverKey}`,
      },
      body: JSON.stringify({
        registration_ids: tokens,
        notification,
        data,
        priority: 'high',
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('[NotificationService] Failed to send FCM message:', errorText);
    }
  } catch (error) {
    console.error('[NotificationService] FCM request error:', error.message);
  }
};

exports.sendAnnouncementNotification = async (tokens = [], payload = {}) => {
  if (!Array.isArray(tokens) || tokens.length === 0) return;

  const uniqueTokens = [...new Set(tokens.filter(Boolean))];
  if (uniqueTokens.length === 0) return;

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

  const batches = chunkArray(uniqueTokens, MAX_BATCH_SIZE);
  await Promise.all(batches.map(batch => sendBatch(batch, notification, data)));
};

