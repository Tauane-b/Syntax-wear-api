import {FastifyRequest, FastifyReply} from 'fastify';
import { ProductFilters } from '../types';
import { getProducts } from '../services/products.services';

export const listProducts = async (
  request: FastifyRequest<{ Querystring: ProductFilters }>,
  reply: FastifyReply
) => {
  const { minPrice, maxPrice, page, limit, search, sortBy, sortOrder } = request.query;
  const parseNumber = (value: unknown) => {
    if (value === undefined) return undefined;
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  };

  const parsedMinPrice = parseNumber(minPrice);
  const parsedMaxPrice = parseNumber(maxPrice);
  const parsedPage = parseNumber(page);
  const parsedLimit = parseNumber(limit);

  if (
    parsedMinPrice === null ||
    parsedMaxPrice === null ||
    parsedPage === null ||
    parsedLimit === null
  ) {
    return reply.code(400).send({ message: 'Price, page, and limit filters must be valid numbers.' });
  }
  if (
    (parsedMinPrice !== undefined && parsedMinPrice < 0) ||
    (parsedMaxPrice !== undefined && parsedMaxPrice < 0) ||
    (parsedPage !== undefined && (!Number.isInteger(parsedPage) || parsedPage < 1)) ||
    (parsedLimit !== undefined && (!Number.isInteger(parsedLimit) || parsedLimit < 1)) ||
    (parsedMinPrice !== undefined && parsedMaxPrice !== undefined && parsedMinPrice > parsedMaxPrice)
  ) {
    return reply.code(400).send({ message: 'Product filters contain invalid values.' });
  }
  if (sortBy !== undefined && !['price', 'name', 'createdAt'].includes(sortBy)) {
    return reply.code(400).send({ message: 'sortBy must be price, name, or createdAt.' });
  }
  if (sortOrder !== undefined && !['asc', 'desc'].includes(sortOrder)) {
    return reply.code(400).send({ message: 'sortOrder must be asc or desc.' });
  }

  const result = await getProducts({
    minPrice: parsedMinPrice ?? undefined,
    maxPrice: parsedMaxPrice ?? undefined,
    page: parsedPage ?? undefined,
    limit: parsedLimit ?? undefined,
    search,
    sortBy,
    sortOrder,
  });
  reply.send(result);
};