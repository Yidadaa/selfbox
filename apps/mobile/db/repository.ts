import { and, desc, eq, isNotNull, sql } from "drizzle-orm";
import type { ExpoSQLiteDatabase } from "drizzle-orm/expo-sqlite";
import {
  chatIconSchema,
  chatInputSchema,
  messageImages,
  type Payload,
  payloadSchema,
  type Role,
  roleSchema,
} from "./payload";
import * as schema from "./schema";

const { chats, messages } = schema;
export const defaultChatId = "monologue";
export type Repository = ReturnType<typeof createRepository>;

export function createRepository(
  db: ExpoSQLiteDatabase<typeof schema>,
  newId: () => string,
  now = Date.now,
) {
  function ensureDefault() {
    const timestamp = now();
    db.insert(chats)
      .values({
        id: defaultChatId,
        name: "",
        icon: { type: "lucide", name: "notebook" },
        isDefault: true,
        createdAt: timestamp,
        updatedAt: timestamp,
      })
      .onConflictDoNothing()
      .run();
  }
  function parseMessage(message: schema.Message): schema.Message {
    return {
      ...message,
      role: roleSchema.parse(message.role),
      payload: payloadSchema.parse(message.payload),
    };
  }
  function getMessage(id: string) {
    const row = db.select().from(messages).where(eq(messages.id, id)).get();
    if (!row) throw new Error("Message not found");
    return parseMessage(row);
  }
  ensureDefault();
  return {
    listChats() {
      return db
        .select({ chat: chats, latest: messages })
        .from(chats)
        .leftJoin(
          messages,
          eq(
            messages.id,
            sql`(SELECT id FROM messages WHERE chat_id = ${chats.id} ORDER BY created_at DESC, id DESC LIMIT 1)`,
          ),
        )
        .orderBy(desc(chats.updatedAt), desc(chats.createdAt), chats.id)
        .all()
        .map(({ chat, latest }) => ({
          ...chat,
          icon: chatIconSchema.parse(chat.icon),
          latest: latest ? parseMessage(latest) : null,
        }));
    },
    getChat(id: string) {
      const chat = db.select().from(chats).where(eq(chats.id, id)).get();
      return chat ? { ...chat, icon: chatIconSchema.parse(chat.icon) } : null;
    },
    createChat(input: unknown) {
      const data = chatInputSchema.parse(input);
      const id = newId();
      const timestamp = now();
      db.insert(chats)
        .values({ ...data, id, createdAt: timestamp, updatedAt: timestamp })
        .run();
      return id;
    },
    listMessages(chatId: string) {
      return db
        .select()
        .from(messages)
        .where(eq(messages.chatId, chatId))
        .orderBy(desc(messages.createdAt), desc(messages.id))
        .all()
        .map(parseMessage);
    },
    listPinned(chatId: string) {
      return db
        .select()
        .from(messages)
        .where(and(eq(messages.chatId, chatId), isNotNull(messages.pinnedAt)))
        .orderBy(desc(messages.pinnedAt))
        .all()
        .map(parseMessage);
    },
    send(chatId: string, input: Payload, role: Role = "user") {
      const payload = payloadSchema.parse(input);
      const validRole = roleSchema.parse(role);
      const id = newId();
      const timestamp = now();
      db.transaction((tx) => {
        tx.insert(messages)
          .values({
            id,
            chatId,
            role: validRole,
            payload,
            createdAt: timestamp,
            updatedAt: timestamp,
          })
          .run();
        tx.update(chats)
          .set({ updatedAt: timestamp })
          .where(eq(chats.id, chatId))
          .run();
      });
      return id;
    },
    edit(id: string, input: Payload) {
      getMessage(id);
      db.update(messages)
        .set({ payload: payloadSchema.parse(input), updatedAt: now() })
        .where(eq(messages.id, id))
        .run();
    },
    togglePin(id: string) {
      const message = getMessage(id);
      db.update(messages)
        .set({ pinnedAt: message.pinnedAt === null ? now() : null })
        .where(eq(messages.id, id))
        .run();
    },
    deleteMessage(id: string) {
      const message = getMessage(id);
      db.transaction((tx) => {
        tx.delete(messages).where(eq(messages.id, id)).run();
        const latest = tx
          .select()
          .from(messages)
          .where(eq(messages.chatId, message.chatId))
          .orderBy(desc(messages.createdAt), desc(messages.id))
          .get();
        const chat = tx
          .select()
          .from(chats)
          .where(eq(chats.id, message.chatId))
          .get();
        tx.update(chats)
          .set({ updatedAt: latest?.createdAt ?? chat?.createdAt ?? now() })
          .where(eq(chats.id, message.chatId))
          .run();
      });
    },
    imageFiles() {
      return db
        .select({ payload: messages.payload })
        .from(messages)
        .all()
        .flatMap(({ payload }) => {
          const parsed = payloadSchema.parse(payload);
          return messageImages(parsed).map((image) => image.file);
        });
    },
    clear() {
      db.transaction((tx) => {
        tx.delete(chats).run();
        ensureDefault();
      });
    },
  };
}
