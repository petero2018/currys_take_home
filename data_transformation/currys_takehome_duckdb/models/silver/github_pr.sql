WITH source_data AS (

    SELECT
        CAST(pr.number AS INTEGER)        AS pr_number,
        CAST(pr.url AS VARCHAR)           AS pr_url,
        CAST(pr.title AS VARCHAR)         AS pr_title,
        CAST(pr.body AS VARCHAR)          AS pr_body,
        CAST(pr.author__login AS VARCHAR) AS author_login,
        CAST(pr.author__avatar_url AS VARCHAR) AS author_avatar_url,
        CAST(pr.author__url AS VARCHAR)   AS author_url,
        CAST(pr.author_association AS VARCHAR) AS author_association,
        CAST(pr.state AS VARCHAR)         AS pr_state,
        CAST(pr.closed AS BOOLEAN)        AS is_closed,
        CAST(pr.created_at AS TIMESTAMP)  AS created_at,
        CAST(pr.updated_at AS TIMESTAMP)  AS updated_at,
        CAST(pr.closed_at AS TIMESTAMP)   AS closed_at,
        CAST(pr.reactions_total_count AS INTEGER) AS reactions_total_count,
        CAST(pr.comments_total_count AS INTEGER) AS comments_total_count,
        CAST(pr._dlt_load_id AS VARCHAR)  AS _dlt_load_id,
        CAST(pr._dlt_id AS VARCHAR)       AS _dlt_id
    FROM read_ndjson(
            'azure://currysprodfs/github/petero2018_currys_take_home_pull_requests/pull_requests/*.jsonl.gz'
         ) pr
)

SELECT *
FROM source_data
