-- Create the destination dataset before building analysis tables.

CREATE SCHEMA IF NOT EXISTS
  `ga4-product-analytics-511413.analytics`
OPTIONS (
  location = 'US',
  description = 'GA4 ecommerce portfolio: event, session, user, and order analysis tables'
);
