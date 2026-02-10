# PostgreSQL Data Warehouse Initialization

This project provides a PostgreSQL container initialized as a **Data Warehouse**,
with a dedicated database (`data_warehouse`) and logical schemas (`bronze`, `silver`, `gold`).

---

### Start PostgreSQL

On the root of the project, run :

```bash
docker compose up
```

On first startup, PostgreSQL is initialized with:
- a superuser: postgres
- a database: data_warehouse
- schemas: bronze, silver, gold

⚠️ Initialization scripts run only once, when the Docker volume is created.

---

### Verify database and schemas

You can access to the database via another terminal :

```bash
docker exec -it <container_name> psql -U <user> -d <database>
```

- <container_name> : `dwh_postgres`
- <user> : `postgres` (superuser)
- <database> : `postgres` (default system database)

Then, look at the different databases :

```bash
\l
```
You should see `data_warehouse` among them.

Connect to it :

```bash
\connect data_warehouse
```

Verify schemas :

```bash
\dn
```
You should have:
- `bronze`
- `silver`
- `gold`

---

### Note : Reset initialization

If you modify initialization script and want to re-run it:
```bash
docker compose down -v
docker compose up
```
⚠️ **This will delete all existing data**, be sure to have a backup if needed.