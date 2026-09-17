import { sql } from "drizzle-orm";
import {
  check,
  index,
  integer,
  sqliteTable,
  text,
  uniqueIndex,
} from "drizzle-orm/sqlite-core";
import type { ChatIcon, Payload } from "./payload";

export const chats = sqliteTable(
  "chats",
  {
    id: text("id").primaryKey(),
    name: text("name").notNull(),
    icon: text("icon", { mode: "json" }).$type<ChatIcon>().notNull(),
    isDefault: integer("is_default", { mode: "boolean" })
      .notNull()
      .default(false),
    createdAt: integer("created_at").notNull(),
    updatedAt: integer("updated_at").notNull(),
  },
  (table) => [
    uniqueIndex("chats_default")
      .on(table.isDefault)
      .where(sql`${table.isDefault} = 1`),
    check("chats_icon_json", sql`json_valid(${table.icon})`),
  ],
);

export const messages = sqliteTable(
  "messages",
  {
    id: text("id").primaryKey(),
    chatId: text("chat_id")
      .notNull()
      .references(() => chats.id, { onDelete: "cascade" }),
    role: text("role", { enum: ["user", "bot"] })
      .notNull()
      .default("user"),
    payload: text("payload", { mode: "json" }).$type<Payload>().notNull(),
    pinnedAt: integer("pinned_at"),
    createdAt: integer("created_at").notNull(),
    updatedAt: integer("updated_at").notNull(),
  },
  (table) => [
    check("messages_role", sql`${table.role} IN ('user', 'bot')`),
    check("messages_payload_json", sql`json_valid(${table.payload})`),
    index("messages_chat_created").on(table.chatId, table.createdAt, table.id),
    index("messages_chat_pinned").on(table.chatId, table.pinnedAt),
  ],
);

export type Chat = typeof chats.$inferSelect;
export type Message = typeof messages.$inferSelect;
