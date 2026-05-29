const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
} = require("@aws-sdk/lib-dynamodb");
const {
  ApiGatewayManagementApiClient,
  PostToConnectionCommand,
} = require("@aws-sdk/client-apigatewaymanagementapi");

const client = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const connectionsTable = process.env.CONNECTIONS_TABLE;
const presenceTable = process.env.PRESENCE_TABLE;
const usersTable = process.env.USERS_TABLE;
const websocketEndpoint = process.env.WEBSOCKET_ENDPOINT;
const presenceTtlSeconds = Number(process.env.PRESENCE_TTL_SECONDS || "60");

const DEFAULT_PEN_COLOR = "#007AFF";

exports.handler = async (event) => {
  const connectionId = event.requestContext.connectionId;
  const body = parseBody(event.body);
  const action = body.action || event.requestContext.routeKey;

  const sender = await client.send(
    new GetCommand({
      TableName: connectionsTable,
      Key: { connectionId },
    }),
  );

  const userId = sender.Item?.userId;
  if (!userId) {
    return { statusCode: 401, body: "Unknown connection" };
  }

  if (action === "presence" || action === "$default") {
    return handlePresence(userId, connectionId, body);
  }

  if (action === "point") {
    return handlePoint(userId, body);
  }

  return { statusCode: 400, body: "Unknown action" };
};

async function handlePresence(userId, connectionId, body) {
  const mode = body.mode;
  const targetUserId = body.targetUserId;

  if (mode !== "specificUserSend" || !targetUserId) {
    return { statusCode: 400, body: "Invalid presence payload" };
  }

  const expiresAt = Math.floor(Date.now() / 1000) + presenceTtlSeconds;

  await client.send(
    new PutCommand({
      TableName: presenceTable,
      Item: {
        userId,
        mode,
        targetUserId,
        connectionId,
        expiresAt,
      },
    }),
  );

  const peerPresence = await client.send(
    new GetCommand({
      TableName: presenceTable,
      Key: { userId: targetUserId },
    }),
  );

  const peer = peerPresence.Item;
  const isMutual =
    peer &&
    peer.mode === "specificUserSend" &&
    peer.targetUserId === userId &&
    peer.connectionId;

  if (!isMutual) {
    return { statusCode: 200, body: "waitingForPeer" };
  }

  const [selfProfile, peerProfile] = await Promise.all([
    loadUserProfile(userId),
    loadUserProfile(targetUserId),
  ]);

  await client.send(
    new PutCommand({
      TableName: presenceTable,
      Item: {
        ...peer,
        livePeerUserId: userId,
        expiresAt,
      },
    }),
  );

  await client.send(
    new PutCommand({
      TableName: presenceTable,
      Item: {
        userId,
        mode,
        targetUserId,
        connectionId,
        livePeerUserId: targetUserId,
        expiresAt,
      },
    }),
  );

  await Promise.all([
    postToConnection(peer.connectionId, {
      type: "liveSession",
      peerId: userId,
      peerDisplayName: selfProfile.displayName,
      peerColor: selfProfile.defaultPenColor,
      bidirectional: true,
    }),
    postToConnection(connectionId, {
      type: "liveSession",
      peerId: targetUserId,
      peerDisplayName: peerProfile.displayName,
      peerColor: peerProfile.defaultPenColor,
      bidirectional: true,
    }),
  ]);

  return { statusCode: 200, body: "liveSessionStarted" };
}

async function handlePoint(userId, body) {
  const presence = await client.send(
    new GetCommand({
      TableName: presenceTable,
      Key: { userId },
    }),
  );

  const peerUserId = presence.Item?.livePeerUserId;
  if (!peerUserId) {
    return { statusCode: 409, body: "No active live session" };
  }

  const peerPresence = await client.send(
    new GetCommand({
      TableName: presenceTable,
      Key: { userId: peerUserId },
    }),
  );

  const peerConnectionId = peerPresence.Item?.connectionId;
  if (!peerConnectionId) {
    return { statusCode: 409, body: "Peer offline" };
  }

  const profile = await loadUserProfile(userId);
  const color = body.color || profile.defaultPenColor || DEFAULT_PEN_COLOR;

  await postToConnection(peerConnectionId, {
    type: "point",
    fromUserId: userId,
    x: body.x,
    y: body.y,
    t: body.t ?? 0,
    break: Boolean(body.break),
    color,
  });

  return { statusCode: 200, body: "pointRelayed" };
}

async function loadUserProfile(userId) {
  const result = await client.send(
    new GetCommand({
      TableName: usersTable,
      Key: { userId },
    }),
  );

  return {
    displayName: result.Item?.displayName || "Tracelet User",
    defaultPenColor: result.Item?.defaultPenColor || DEFAULT_PEN_COLOR,
  };
}

async function postToConnection(connectionId, payload) {
  const api = new ApiGatewayManagementApiClient({ endpoint: websocketEndpoint });
  await api.send(
    new PostToConnectionCommand({
      ConnectionId: connectionId,
      Data: Buffer.from(JSON.stringify(payload)),
    }),
  );
}

function parseBody(body) {
  if (!body) {
    return {};
  }
  try {
    return JSON.parse(body);
  } catch {
    return {};
  }
}
