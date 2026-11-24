import { prisma } from '../utils/prisma';
import { ProductFilters } from '../types';
import { Prisma } from '@prisma/client';

export const getProducts = async (filters: ProductFilters) => {
  const { minPrice, maxPrice, search, page, limit, sortBy, sortOrder } = filters;
  const where: Prisma.ProductWhereInput = {};
  if (minPrice !== undefined || maxPrice !== undefined) {
    where.basePriceCents = {
      ...(minPrice !== undefined ? { gte: minPrice } : {}),
      ...(maxPrice !== undefined ? { lte: maxPrice } : {}),
    };
  }

  if (search?.trim()) {
    where.OR = [
      { name: { contains: search.trim(), mode: 'insensitive' } },
      { description: { contains: search.trim(), mode: 'insensitive' } },
      { slug: { contains: search.trim(), mode: 'insensitive' } },
    ];
  }

  const orderBy: Prisma.ProductOrderByWithRelationInput | undefined = sortBy
    ? { [sortBy === 'price' ? 'basePriceCents' : sortBy]: sortOrder ?? 'asc' }
    : undefined;

  const hasPagination = page !== undefined || limit !== undefined;
  const currentPage = page ?? 1;
  const pageSize = limit ?? 20;
  const result = await prisma.product.findMany({
    where,
    ...(orderBy ? { orderBy } : {}),
    ...(hasPagination ? { skip: (currentPage - 1) * pageSize, take: pageSize } : {}),
  });
  return result;
};