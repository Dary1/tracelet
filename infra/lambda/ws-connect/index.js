const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  PutCommand,
} = require("@aws-sdk/lib-dynamodb");

const client = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const connectionsTable = process.env.CONNECTIONS_TABLE;
const presenceTtlSeconds = Number(process.env.PRESENCE_TTL_SECONDS || "60");

exports.handler = async (event) => {
  const connectionId = event.requestContext.connectionId;
  const userId = event.queryStringParameters?.userId;

  if (!userId) {
    return { statusCode: 401, body: "Missing userId" };
  }

  const expiresAt = Math.floor(Date.now() / 1000) + presenceTtlSeconds * 2;

  await client.send(
    new PutCommand({
      TableName: connectionsTable,
      Item: {
        connectionId,
        userId,
        expiresAt,
      },
    }),
  );

  return { statusCode: 200, body: "connected" };
};
