import "dotenv/config";

const databaseUrl = process.env["DATABASE_URL"];

if (!databaseUrl) {
  throw new Error("DATABASE_URL must be set to use Prisma.");
}

export default {
  schema: "prisma/schema.prisma",
  migrations: {
    path: "prisma/migrations",
    seed: "tsx prisma/seed.ts",
  },
  datasource: {
    url: databaseUrl,
  },
};