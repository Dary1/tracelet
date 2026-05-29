const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  DeleteCommand,
  QueryCommand,
} = require("@aws-sdk/lib-dynamodb");
const { SQSClient, SendMessageCommand, ReceiveMessageCommand, DeleteMessageCommand } =
  require("@aws-sdk/client-sqs");
const { randomUUID } = require("crypto");

const client = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const sqs = new SQSClient({});

const usersTable = process.env.USERS_TABLE;
const friendshipsTable = process.env.FRIENDSHIPS_TABLE;
const pendingDirectTable = process.env.PENDING_DIRECT_TABLE;
const bottleQueueUrl = process.env.BOTTLE_QUEUE_URL;
const bottleTestQueueUrl = process.env.BOTTLE_TEST_QUEUE_URL;
const pendingTtlSeconds = Number(process.env.PENDING_TTL_SECONDS || "86400");

const DEFAULT_PEN_COLOR = "#007AFF";

exports.handler = async (event) => {
  const route = routeFromEvent(event);

  switch (route) {
    case "GET /settings":
      return json(200, await getSettings(event));
    case "PUT /settings":
      return json(200, await putSettings(event));
    case "POST /messages/direct":
      return json(202, await sendDirect(event));
    case "POST /messages/direct/fetch":
      return json(200, await fetchDirect(event));
    case "POST /bottles":
      return json(202, await depositBottle(event));
    case "POST /bottles/pull":
      return json(200, await pullBottle(event));
    case "GET /friends":
      return json(200, await listFriends(event));
    case "POST /friends":
      return json(201, await addFriend(event));
    case "DELETE /friends":
      return json(200, await removeFriend(event));
    case "PUT /friends/name-trace":
      return json(200, await putFriendNameTrace(event));
    default:
      return json(404, { message: "Not found" });
  }
};

function userIdFromEvent(event) {
  return (
    event.requestContext?.authorizer?.jwt?.claims?.sub ||
    event.headers?.["x-user-id"] ||
    event.headers?.["X-User-Id"]
  );
}

async function getSettings(event) {
  const userId = userIdFromEvent(event);
  if (!userId) {
    return { message: "Unauthorized" };
  }

  const result = await client.send(
    new GetCommand({ TableName: usersTable, Key: { userId } }),
  );

  return {
    defaultPenColor: result.Item?.defaultPenColor || DEFAULT_PEN_COLOR,
    notificationsEnabled: result.Item?.notificationsEnabled ?? true,
    muted: result.Item?.muted ?? false,
  };
}

async function putSettings(event) {
  const userId = userIdFromEvent(event);
  if (!userId) {
    return { message: "Unauthorized" };
  }

  const body = JSON.parse(event.body || "{}");
  const defaultPenColor = body.defaultPenColor || DEFAULT_PEN_COLOR;

  await client.send(
    new PutCommand({
      TableName: usersTable,
      Item: {
        userId,
        defaultPenColor,
        notificationsEnabled: body.notificationsEnabled ?? true,
        muted: body.muted ?? false,
        updatedAt: new Date().toISOString(),
      },
    }),
  );

  return { defaultPenColor };
}

async function sendDirect(event) {
  const userId = userIdFromEvent(event);
  const body = JSON.parse(event.body || "{}");
  const messageId = randomUUID();
  const expiresAt = Math.floor(Date.now() / 1000) + pendingTtlSeconds;

  await client.send(
    new PutCommand({
      TableName: pendingDirectTable,
      Item: {
        recipientUserId: body.recipientUserId,
        messageId,
        senderUserId: userId,
        payload: body.payload,
        expiresAt,
      },
    }),
  );

  return { messageId, expiresAt };
}

async function fetchDirect(event) {
  const userId = userIdFromEvent(event);
  const body = JSON.parse(event.body || "{}");

  const result = await client.send(
    new GetCommand({
      TableName: pendingDirectTable,
      Key: {
        recipientUserId: userId,
        messageId: body.messageId,
      },
    }),
  );

  if (!result.Item) {
    return { message: "Not found" };
  }

  await client.send(
    new DeleteCommand({
      TableName: pendingDirectTable,
      Key: {
        recipientUserId: userId,
        messageId: body.messageId,
      },
    }),
  );

  return {
    messageId: result.Item.messageId,
    senderUserId: result.Item.senderUserId,
    payload: result.Item.payload,
  };
}

async function depositBottle(event) {
  const userId = userIdFromEvent(event);
  const body = JSON.parse(event.body || "{}");

  await sqs.send(
    new SendMessageCommand({
      QueueUrl: bottleQueueUrlFromEvent(event),
      MessageGroupId: "bottle-ocean",
      MessageBody: JSON.stringify({
        senderUserId: userId,
        payload: body.payload,
        createdAt: new Date().toISOString(),
      }),
    }),
  );

  return { accepted: true };
}

async function pullBottle(event) {
  const receive = await sqs.send(
    new ReceiveMessageCommand({
      QueueUrl: bottleQueueUrlFromEvent(event),
      MaxNumberOfMessages: 1,
      WaitTimeSeconds: 1,
    }),
  );

  const message = receive.Messages?.[0];
  if (!message) {
    return { message: "No bottles available" };
  }

  await sqs.send(
    new DeleteMessageCommand({
      QueueUrl: bottleQueueUrlFromEvent(event),
      ReceiptHandle: message.ReceiptHandle,
    }),
  );

  return JSON.parse(message.Body);
}

function bottleQueueUrlFromEvent(event) {
  const testHeader =
    event.headers?.["x-tracelet-test-queue"] ||
    event.headers?.["X-Tracelet-Test-Queue"];
  if (testHeader === "true" && bottleTestQueueUrl) {
    return bottleTestQueueUrl;
  }
  return bottleQueueUrl;
}

async function listFriends(event) {
  const userId = userIdFromEvent(event);
  if (!userId) {
    return { message: "Unauthorized" };
  }

  const result = await client.send(
    new QueryCommand({
      TableName: friendshipsTable,
      KeyConditionExpression: "userId = :userId",
      ExpressionAttributeValues: { ":userId": userId },
    }),
  );

  return {
    friends: (result.Items || []).map((item) => ({
      id: item.friendUserId,
      displayName: item.displayName || item.friendUserId,
      nameTracePoints: item.nameTracePoints || [],
    })),
  };
}

async function addFriend(event) {
  const userId = userIdFromEvent(event);
  if (!userId) {
    return { message: "Unauthorized" };
  }

  const body = JSON.parse(event.body || "{}");
  if (!body.friendUserId) {
    return { message: "friendUserId required" };
  }

  await client.send(
    new PutCommand({
      TableName: friendshipsTable,
      Item: {
        userId,
        friendUserId: body.friendUserId,
        displayName: body.displayName || body.friendUserId,
        nameTracePoints: body.nameTracePoints || [],
        createdAt: new Date().toISOString(),
      },
    }),
  );

  return { friendUserId: body.friendUserId };
}

async function removeFriend(event) {
  const userId = userIdFromEvent(event);
  if (!userId) {
    return { message: "Unauthorized" };
  }

  const body = JSON.parse(event.body || "{}");
  if (!body.friendUserId) {
    return { message: "friendUserId required" };
  }

  await client.send(
    new DeleteCommand({
      TableName: friendshipsTable,
      Key: {
        userId,
        friendUserId: body.friendUserId,
      },
    }),
  );

  return { removed: body.friendUserId };
}

async function putFriendNameTrace(event) {
  const userId = userIdFromEvent(event);
  if (!userId) {
    return { message: "Unauthorized" };
  }

  const body = JSON.parse(event.body || "{}");
  if (!body.friendUserId) {
    return { message: "friendUserId required" };
  }

  const existing = await client.send(
    new GetCommand({
      TableName: friendshipsTable,
      Key: {
        userId,
        friendUserId: body.friendUserId,
      },
    }),
  );

  await client.send(
    new PutCommand({
      TableName: friendshipsTable,
      Item: {
        userId,
        friendUserId: body.friendUserId,
        displayName:
          body.displayName ||
          existing.Item?.displayName ||
          body.friendUserId,
        nameTracePoints: body.nameTracePoints || [],
        createdAt: existing.Item?.createdAt || new Date().toISOString(),
      },
    }),
  );

  return { friendUserId: body.friendUserId };
}

function routeFromEvent(event) {
  const routeKey = event.requestContext?.routeKey;
  if (routeKey && routeKey !== "$default") {
    return routeKey;
  }

  const method = event.requestContext?.http?.method || "GET";
  let path = event.rawPath || event.requestContext?.http?.path || "/";
  const stage = event.requestContext?.stage;
  if (stage && path.startsWith(`/${stage}/`)) {
    path = path.slice(stage.length + 1);
  } else if (stage && path === `/${stage}`) {
    path = "/";
  }
  return `${method} ${path}`;
}

function json(statusCode, body) {
  return {
    statusCode,
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  };
}
