## Requirements

* Docker
* docker-compose
* postgres

## Building
docker-compose build

## Running
docker-compose up -d

## Stopping
docker-compose down

## Restarting
docker-compose down && docker-compose build && docker-compose up -d

## Connecting via postgres command line

### Extracting container
psql -h localhost -p 3301 -U postgres

### Cleaning container
psql -h localhost -p 3302 -U postgres

### Conforming container
psql -h localhost -p 3303 -U postgres

### Final container
psql -h localhost -p 3304 -U postgres
