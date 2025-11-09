WITH source_data AS (

    SELECT
        pr.number                    AS pr_number,
        pr.url                       AS pr_url,
        pr.title                     AS pr_title,
        pr.body                      AS pr_body,
        pr.author__login             AS author_login,
        pr.author__avatar_url        AS author_avatar_url,
        pr.author__url               AS author_url,
        pr.author_association        AS author_association,
        pr.state                     AS pr_state,
        pr.closed                    AS is_closed,
        pr.created_at                AS created_at,
        pr.updated_at                AS updated_at,
        pr.closed_at                 AS closed_at,
        pr.reactions_total_count     AS reactions_total_count,
        pr.comments_total_count      AS comments_total_count,
        pr._dlt_load_id              AS _dlt_load_id,
        pr._dlt_id                   AS _dlt_id
    FROM read_ndjson(
            'azure://currysprodfs/github/petero2018_currys_take_home_pull_requests/pull_requests/*.jsonl.gz'
         ) pr
)

SELECT *
FROM source_data