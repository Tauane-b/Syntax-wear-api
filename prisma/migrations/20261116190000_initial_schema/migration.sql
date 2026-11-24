-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('CUSTOMER', 'ADMIN');

-- CreateEnum
CREATE TYPE "ProductStatus" AS ENUM ('DRAFT', 'ACTIVE', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "CartStatus" AS ENUM ('ACTIVE', 'CONVERTED', 'ABANDONED');

-- CreateEnum
CREATE TYPE "ShippingQuoteStatus" AS ENUM ('VALID', 'EXPIRED', 'USED');

-- CreateEnum
CREATE TYPE "OrderStatus" AS ENUM ('PENDING_PAYMENT', 'PAID', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED', 'REFUNDED');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('PENDING', 'PAID', 'FAILED', 'CANCELLED', 'REFUNDED');

-- CreateEnum
CREATE TYPE "InventoryMovementType" AS ENUM ('RESTOCK', 'RESERVATION', 'SALE', 'RELEASE', 'ADJUSTMENT', 'RETURN');

-- CreateTable
CREATE TABLE "user_profiles" (
    "id" UUID NOT NULL,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "cpf" TEXT NOT NULL,
    "birthDate" DATE,
    "cellphone" TEXT,
    "role" "UserRole" NOT NULL DEFAULT 'CUSTOMER',
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "user_profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "addresses" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "recipientName" TEXT NOT NULL,
    "label" TEXT,
    "cep" VARCHAR(9) NOT NULL,
    "street" TEXT NOT NULL,
    "number" TEXT NOT NULL,
    "complement" TEXT,
    "neighborhood" TEXT NOT NULL,
    "city" TEXT NOT NULL,
    "state" VARCHAR(2) NOT NULL,
    "country" VARCHAR(2) NOT NULL DEFAULT 'BR',
    "isDefault" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "addresses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "categories" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "description" TEXT,
    "imageUrl" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "products" (
    "id" UUID NOT NULL,
    "categoryId" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "description" TEXT,
    "basePriceCents" INTEGER NOT NULL,
    "compareAtPriceCents" INTEGER,
    "color" TEXT,
    "status" "ProductStatus" NOT NULL DEFAULT 'DRAFT',
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "products_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "product_images" (
    "id" UUID NOT NULL,
    "productId" UUID NOT NULL,
    "url" TEXT NOT NULL,
    "altText" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "product_images_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "product_variants" (
    "id" UUID NOT NULL,
    "productId" UUID NOT NULL,
    "sku" TEXT NOT NULL,
    "size" TEXT NOT NULL,
    "color" TEXT NOT NULL,
    "priceCents" INTEGER,
    "stockQuantity" INTEGER NOT NULL DEFAULT 0,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "product_variants_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "carts" (
    "id" UUID NOT NULL,
    "userId" UUID,
    "sessionToken" VARCHAR(128),
    "status" "CartStatus" NOT NULL DEFAULT 'ACTIVE',
    "expiresAt" TIMESTAMPTZ(6),
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "carts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cart_items" (
    "id" UUID NOT NULL,
    "cartId" UUID NOT NULL,
    "variantId" UUID NOT NULL,
    "quantity" INTEGER NOT NULL,
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "cart_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "shipping_quotes" (
    "id" UUID NOT NULL,
    "userId" UUID,
    "cep" VARCHAR(9) NOT NULL,
    "serviceCode" TEXT,
    "serviceName" TEXT,
    "shippingCents" INTEGER NOT NULL,
    "estimatedDays" INTEGER,
    "source" TEXT NOT NULL DEFAULT 'ESTIMATE',
    "status" "ShippingQuoteStatus" NOT NULL DEFAULT 'VALID',
    "expiresAt" TIMESTAMPTZ(6) NOT NULL,
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "shipping_quotes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "orders" (
    "id" UUID NOT NULL,
    "number" TEXT NOT NULL,
    "userId" UUID NOT NULL,
    "shippingQuoteId" UUID,
    "status" "OrderStatus" NOT NULL DEFAULT 'PENDING_PAYMENT',
    "paymentStatus" "PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "subtotalCents" INTEGER NOT NULL,
    "shippingCents" INTEGER NOT NULL,
    "discountCents" INTEGER NOT NULL DEFAULT 0,
    "totalCents" INTEGER NOT NULL,
    "currency" CHAR(3) NOT NULL DEFAULT 'BRL',
    "paymentProvider" TEXT,
    "paymentReference" TEXT,
    "paidAt" TIMESTAMPTZ(6),
    "shippedAt" TIMESTAMPTZ(6),
    "deliveredAt" TIMESTAMPTZ(6),
    "cancelledAt" TIMESTAMPTZ(6),
    "recipientName" TEXT NOT NULL,
    "shippingCep" VARCHAR(9) NOT NULL,
    "shippingStreet" TEXT NOT NULL,
    "shippingNumber" TEXT NOT NULL,
    "shippingComplement" TEXT,
    "shippingNeighborhood" TEXT NOT NULL,
    "shippingCity" TEXT NOT NULL,
    "shippingState" VARCHAR(2) NOT NULL,
    "shippingCountry" VARCHAR(2) NOT NULL DEFAULT 'BR',
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "orders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "order_items" (
    "id" UUID NOT NULL,
    "orderId" UUID NOT NULL,
    "productId" UUID,
    "variantId" UUID,
    "productName" TEXT NOT NULL,
    "sku" TEXT NOT NULL,
    "size" TEXT NOT NULL,
    "color" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL,
    "unitPriceCents" INTEGER NOT NULL,
    "lineTotalCents" INTEGER NOT NULL,
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "order_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "newsletter_subscriptions" (
    "id" UUID NOT NULL,
    "email" TEXT NOT NULL,
    "unsubscribeToken" UUID NOT NULL,
    "consentAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "unsubscribedAt" TIMESTAMPTZ(6),
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "newsletter_subscriptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "inventory_movements" (
    "id" UUID NOT NULL,
    "variantId" UUID NOT NULL,
    "actorUserId" UUID,
    "type" "InventoryMovementType" NOT NULL,
    "quantityDelta" INTEGER NOT NULL,
    "reason" TEXT,
    "referenceType" TEXT,
    "referenceId" UUID,
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "inventory_movements_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "user_profiles_email_key" ON "user_profiles"("email");

-- CreateIndex
CREATE UNIQUE INDEX "user_profiles_cpf_key" ON "user_profiles"("cpf");

-- CreateIndex
CREATE INDEX "addresses_userId_idx" ON "addresses"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "categories_slug_key" ON "categories"("slug");

-- CreateIndex
CREATE INDEX "categories_active_sortOrder_idx" ON "categories"("active", "sortOrder");

-- CreateIndex
CREATE UNIQUE INDEX "products_slug_key" ON "products"("slug");

-- CreateIndex
CREATE INDEX "products_categoryId_status_idx" ON "products"("categoryId", "status");

-- CreateIndex
CREATE INDEX "products_status_createdAt_idx" ON "products"("status", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "product_images_productId_sortOrder_key" ON "product_images"("productId", "sortOrder");

-- CreateIndex
CREATE UNIQUE INDEX "product_variants_sku_key" ON "product_variants"("sku");

-- CreateIndex
CREATE INDEX "product_variants_productId_active_idx" ON "product_variants"("productId", "active");

-- CreateIndex
CREATE UNIQUE INDEX "product_variants_productId_size_color_key" ON "product_variants"("productId", "size", "color");

-- CreateIndex
CREATE UNIQUE INDEX "carts_sessionToken_key" ON "carts"("sessionToken");

-- CreateIndex
CREATE INDEX "carts_userId_status_idx" ON "carts"("userId", "status");

-- CreateIndex
CREATE INDEX "cart_items_variantId_idx" ON "cart_items"("variantId");

-- CreateIndex
CREATE UNIQUE INDEX "cart_items_cartId_variantId_key" ON "cart_items"("cartId", "variantId");

-- CreateIndex
CREATE INDEX "shipping_quotes_userId_createdAt_idx" ON "shipping_quotes"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "shipping_quotes_status_expiresAt_idx" ON "shipping_quotes"("status", "expiresAt");

-- CreateIndex
CREATE UNIQUE INDEX "orders_number_key" ON "orders"("number");

-- CreateIndex
CREATE INDEX "orders_userId_createdAt_idx" ON "orders"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "orders_status_createdAt_idx" ON "orders"("status", "createdAt");

-- CreateIndex
CREATE INDEX "orders_shippingQuoteId_idx" ON "orders"("shippingQuoteId");

-- CreateIndex
CREATE INDEX "order_items_orderId_idx" ON "order_items"("orderId");

-- CreateIndex
CREATE INDEX "order_items_productId_idx" ON "order_items"("productId");

-- CreateIndex
CREATE INDEX "order_items_variantId_idx" ON "order_items"("variantId");

-- CreateIndex
CREATE UNIQUE INDEX "newsletter_subscriptions_email_key" ON "newsletter_subscriptions"("email");

-- CreateIndex
CREATE UNIQUE INDEX "newsletter_subscriptions_unsubscribeToken_key" ON "newsletter_subscriptions"("unsubscribeToken");

-- CreateIndex
CREATE INDEX "inventory_movements_variantId_createdAt_idx" ON "inventory_movements"("variantId", "createdAt");

-- CreateIndex
CREATE INDEX "inventory_movements_actorUserId_createdAt_idx" ON "inventory_movements"("actorUserId", "createdAt");

-- CreateIndex
CREATE INDEX "inventory_movements_referenceType_referenceId_idx" ON "inventory_movements"("referenceType", "referenceId");

-- AddForeignKey
ALTER TABLE "addresses" ADD CONSTRAINT "addresses_userId_fkey" FOREIGN KEY ("userId") REFERENCES "user_profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "products" ADD CONSTRAINT "products_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "product_images" ADD CONSTRAINT "product_images_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "product_variants" ADD CONSTRAINT "product_variants_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "carts" ADD CONSTRAINT "carts_userId_fkey" FOREIGN KEY ("userId") REFERENCES "user_profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cart_items" ADD CONSTRAINT "cart_items_cartId_fkey" FOREIGN KEY ("cartId") REFERENCES "carts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cart_items" ADD CONSTRAINT "cart_items_variantId_fkey" FOREIGN KEY ("variantId") REFERENCES "product_variants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shipping_quotes" ADD CONSTRAINT "shipping_quotes_userId_fkey" FOREIGN KEY ("userId") REFERENCES "user_profiles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_userId_fkey" FOREIGN KEY ("userId") REFERENCES "user_profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_shippingQuoteId_fkey" FOREIGN KEY ("shippingQuoteId") REFERENCES "shipping_quotes"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_variantId_fkey" FOREIGN KEY ("variantId") REFERENCES "product_variants"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inventory_movements" ADD CONSTRAINT "inventory_movements_variantId_fkey" FOREIGN KEY ("variantId") REFERENCES "product_variants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inventory_movements" ADD CONSTRAINT "inventory_movements_actorUserId_fkey" FOREIGN KEY ("actorUserId") REFERENCES "user_profiles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- -- Keep profile identities tied to Supabase Auth, which owns the auth schema.
-- ALTER TABLE "user_profiles"
-- ADD CONSTRAINT "user_profiles_auth_user_fkey"
-- FOREIGN KEY ("id") REFERENCES auth.users("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Enforce non-negative monetary values and positive item quantities.
ALTER TABLE "products"
ADD CONSTRAINT "products_base_price_nonnegative" CHECK ("basePriceCents" >= 0),
ADD CONSTRAINT "products_compare_price_nonnegative" CHECK ("compareAtPriceCents" IS NULL OR "compareAtPriceCents" >= 0);

ALTER TABLE "product_variants"
ADD CONSTRAINT "product_variants_stock_nonnegative" CHECK ("stockQuantity" >= 0),
ADD CONSTRAINT "product_variants_price_nonnegative" CHECK ("priceCents" IS NULL OR "priceCents" >= 0);

ALTER TABLE "cart_items"
ADD CONSTRAINT "cart_items_quantity_positive" CHECK ("quantity" > 0);

ALTER TABLE "shipping_quotes"
ADD CONSTRAINT "shipping_quotes_cost_nonnegative" CHECK ("shippingCents" >= 0),
ADD CONSTRAINT "shipping_quotes_days_nonnegative" CHECK ("estimatedDays" IS NULL OR "estimatedDays" >= 0);

ALTER TABLE "orders"
ADD CONSTRAINT "orders_amounts_nonnegative" CHECK (
  "subtotalCents" >= 0 AND
  "shippingCents" >= 0 AND
  "discountCents" >= 0 AND
  "totalCents" >= 0
);

ALTER TABLE "order_items"
ADD CONSTRAINT "order_items_amounts_valid" CHECK (
  "quantity" > 0 AND
  "unitPriceCents" >= 0 AND
  "lineTotalCents" >= 0
);

CREATE UNIQUE INDEX "addresses_one_default_per_user_key"
ON "addresses"("userId")
WHERE "isDefault" = true;

-- No client-facing policies are defined yet; the API uses its trusted backend connection.
ALTER TABLE "user_profiles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "addresses" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "categories" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "products" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "product_images" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "product_variants" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "carts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "cart_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "shipping_quotes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "orders" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "order_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "newsletter_subscriptions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "inventory_movements" ENABLE ROW LEVEL SECURITY;
