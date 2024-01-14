#!/bin/sh

# Run migrations
/app/bin/migrate

# Start the main application
exec /app/bin/server
