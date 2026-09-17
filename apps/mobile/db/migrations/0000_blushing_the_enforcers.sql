CREATE TABLE `chats` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`icon` text NOT NULL,
	`is_default` integer DEFAULT false NOT NULL,
	`created_at` integer NOT NULL,
	`updated_at` integer NOT NULL,
	CONSTRAINT "chats_icon_json" CHECK(json_valid("chats"."icon"))
);
--> statement-breakpoint
CREATE UNIQUE INDEX `chats_default` ON `chats` (`is_default`) WHERE "chats"."is_default" = 1;--> statement-breakpoint
CREATE TABLE `messages` (
	`id` text PRIMARY KEY NOT NULL,
	`chat_id` text NOT NULL,
	`role` text DEFAULT 'user' NOT NULL,
	`payload` text NOT NULL,
	`pinned_at` integer,
	`created_at` integer NOT NULL,
	`updated_at` integer NOT NULL,
	FOREIGN KEY (`chat_id`) REFERENCES `chats`(`id`) ON UPDATE no action ON DELETE cascade,
	CONSTRAINT "messages_role" CHECK("messages"."role" IN ('user', 'bot')),
	CONSTRAINT "messages_payload_json" CHECK(json_valid("messages"."payload"))
);
--> statement-breakpoint
CREATE INDEX `messages_chat_created` ON `messages` (`chat_id`,`created_at`,`id`);--> statement-breakpoint
CREATE INDEX `messages_chat_pinned` ON `messages` (`chat_id`,`pinned_at`);