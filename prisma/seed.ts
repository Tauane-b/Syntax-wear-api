import "dotenv/config";
import { Client } from "pg";

const databaseUrl = process.env["DATABASE_URL"];

if (!databaseUrl) {
  throw new Error("DATABASE_URL must be set to run the seed.");
}

const categories = [
  { name: "Casual", slug: "casual", sortOrder: 100 },
  { name: "Esportivo", slug: "esportivo", sortOrder: 101 },
  { name: "Urbano", slug: "urbano", sortOrder: 102 },
  { name: "Social", slug: "social", sortOrder: 103 },
];

const products = [
  {
    name: "Tênis Horizonte",
    slug: "tenis-horizonte",
    description: "Tênis casual leve para acompanhar a rotina.",
    basePriceCents: 24990,
    color: "Branco",
    categorySlug: "casual",
  },
  {
    name: "Tênis Pulso",
    slug: "tenis-pulso",
    description: "Tênis esportivo com visual dinâmico e confortável.",
    basePriceCents: 31990,
    color: "Preto",
    categorySlug: "esportivo",
  },
  {
    name: "Tênis Asfalto",
    slug: "tenis-asfalto",
    description: "Modelo urbano versátil para compor diferentes looks.",
    basePriceCents: 27990,
    color: "Cinza",
    categorySlug: "urbano",
  },
  {
    name: "Sapato Traço",
    slug: "sapato-traco",
    description: "Sapato social de linhas clássicas para ocasiões especiais.",
    basePriceCents: 38990,
    color: "Preto",
    categorySlug: "social",
  },
  {
    name: "Tênis Brisa",
    slug: "tenis-brisa",
    description: "Tênis casual de perfil baixo e estilo minimalista.",
    basePriceCents: 22990,
    color: "Areia",
    categorySlug: "casual",
  },
  {
    name: "Tênis Ritmo",
    slug: "tenis-ritmo",
    description: "Tênis esportivo para treinos e caminhadas.",
    basePriceCents: 34990,
    color: "Azul-marinho",
    categorySlug: "esportivo",
  },
  {
    name: "Bota Travessia",
    slug: "bota-travessia",
    description: "Bota urbana resistente com acabamento contemporâneo.",
    basePriceCents: 42990,
    color: "Marrom",
    categorySlug: "urbano",
  },
  {
    name: "Mocassim Encontro",
    slug: "mocassim-encontro",
    description: "Mocassim versátil para combinações casuais ou alinhadas.",
    basePriceCents: 36990,
    color: "Caramelo",
    categorySlug: "social",
  },
  {
    name: "Tênis Nuvem",
    slug: "tenis-nuvem",
    description: "Tênis casual macio para o uso diário.",
    basePriceCents: 25990,
    color: "Verde-oliva",
    categorySlug: "casual",
  },
  {
    name: "Tênis Impulso",
    slug: "tenis-impulso",
    description: "Tênis esportivo com construção leve para movimento.",
    basePriceCents: 33990,
    color: "Vermelho",
    categorySlug: "esportivo",
  },
];

async function seed() {
  const client = new Client({
    connectionString: databaseUrl,
    ssl: { rejectUnauthorized: false },
  });

  await client.connect();

  try {
    await client.query("BEGIN");

    for (const category of categories) {
      await client.query(
        `INSERT INTO "categories" ("id", "name", "slug", "sortOrder", "active", "createdAt", "updatedAt")
         VALUES (gen_random_uuid(), $1, $2, $3, true, NOW(), NOW())
         ON CONFLICT ("slug") DO NOTHING`,
        [category.name, category.slug, category.sortOrder],
      );
    }

    const categoryResult = await client.query<{ id: string; slug: string }>(
      `SELECT "id", "slug" FROM "categories" WHERE "slug" = ANY($1::text[])`,
      [categories.map(({ slug }) => slug)],
    );
    const categoryIds = new Map(
      categoryResult.rows.map(({ id, slug }) => [slug, id]),
    );

    for (const product of products) {
      const categoryId = categoryIds.get(product.categorySlug);
      if (!categoryId) {
        throw new Error(`Seed category "${product.categorySlug}" was not found.`);
      }

      await client.query(
        `INSERT INTO "products"
           ("id", "categoryId", "name", "slug", "description", "basePriceCents", "color", "status", "createdAt", "updatedAt")
         VALUES
           (gen_random_uuid(), $1, $2, $3, $4, $5, $6, 'ACTIVE', NOW(), NOW())
         ON CONFLICT ("slug") DO UPDATE SET
           "categoryId" = EXCLUDED."categoryId",
           "name" = EXCLUDED."name",
           "description" = EXCLUDED."description",
           "basePriceCents" = EXCLUDED."basePriceCents",
           "color" = EXCLUDED."color",
           "status" = EXCLUDED."status",
           "updatedAt" = NOW()`,
        [
          categoryId,
          product.name,
          product.slug,
          product.description,
          product.basePriceCents,
          product.color,
        ],
      );
    }

    await client.query("COMMIT");
    console.log(`Seed concluído: ${products.length} produtos processados.`);
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    await client.end();
  }
}

seed().catch((error: unknown) => {
  console.error("Falha ao executar seed:", error);
  process.exitCode = 1;
});
