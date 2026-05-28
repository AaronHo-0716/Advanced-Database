# ERD

The canonical entity-relationship diagram for GLCL lives in this folder as
`Advanced_Database.drawio` (24 tables). Open it with [diagrams.net](https://app.diagrams.net/)
or the VS Code Draw.io Integration extension.

**Source-of-truth rule:** the SQL scripts under `schema/` are authoritative for
the database structure. The `.drawio` file is documentation. If they ever
disagree, the scripts win — update the diagram to match.

To export a PNG/PDF snapshot for the report, use **File → Export As** in
draw.io and commit the export alongside the `.drawio` file.
