const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  DeleteCommand,
  GetCommand,
} = require("@aws-sdk/lib-dynamodb");
const {
  ApiGatewayManagementApiClient,
  PostToConnectionCommand,
} = require("@aws-sdk/client-apigatewaymanagementapi");

const client = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const connectionsTable = process.env.CONNECTIONS_TABLE;
const presenceTable = process.env.PRESENCE_TABLE;
const websocketEndpoint = process.env.WEBSOCKET_ENDPOINT;

exports.handler = async (event) => {
  const connectionId = event.requestContext.connectionId;
  const connection = await client.send(
    new GetCommand({
      TableName: connectionsTable,
      Key: { connectionId },
    }),
  );

  const userId = connection.Item?.userId;
  if (userId) {
    await clearLiveSession(userId, connectionId);
    await client.send(
      new DeleteCommand({
        TableName: presenceTable,
        Key: { userId },
      }),
    );
  }

  await client.send(
    new DeleteCommand({
      TableName: connectionsTable,
      Key: { connectionId },
    }),
  );

  return { statusCode: 200, body: "disconnected" };
};

async function clearLiveSession(userId, connectionId) {
  const presence = await client.send(
    new GetCommand({
      TableName: presenceTable,
      Key: { userId },
    }),
  );

  const peerUserId = presence.Item?.livePeerUserId;
  if (!peerUserId) {
    return;
  }

  const peerPresence = await client.send(
    new GetCommand({
      TableName: presenceTable,
      Key: { userId: peerUserId },
    }),
  );

  if (peerPresence.Item?.livePeerUserId === userId) {
    await notifyPeerEnded(peerPresence.Item.connectionId);
    await client.send(
      new DeleteCommand({
        TableName: presenceTable,
        Key: { userId: peerUserId },
      }),
    );
  }
}

async function notifyPeerEnded(peerConnectionId) {
  if (!peerConnectionId || !websocketEndpoint) {
    return;
  }

  const api = new ApiGatewayManagementApiClient({ endpoint: websocketEndpoint });
  try {
    await api.send(
      new PostToConnectionCommand({
        ConnectionId: peerConnectionId,
        Data: Buffer.from(
          JSON.stringify({
            type: "liveSessionEnded",
            reason: "peerDisconnected",
          }),
        ),
      }),
    );
  } catch (error) {
    if (error.statusCode !== 410) {
      console.warn("notifyPeerEnded failed", error);
    }
  }
}
