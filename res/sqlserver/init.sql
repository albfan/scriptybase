CREATE TABLE databasechangelog
(
   ID                  int            IDENTITY PRIMARY KEY,
   MD5SUM              varchar(300),
   FILE                varchar(300),   
   DATE                datetime,
);

ALTER TABLE databasechangelog ADD CONSTRAINT PK_databasechangelog PRIMARY KEY CLUSTERED (ID);
CREATE NONCLUSTERED INDEX PK_databasechangelog_file ON databasechangelog (FILE ASC);
CREATE NONCLUSTERED INDEX PK_databasechangelog_md5 ON databasechangelog (MD5 ASC);

--GRANT INSERT, REFERENCES, DELETE, SELECT, UPDATE ON databasechangelog TO dbo;
