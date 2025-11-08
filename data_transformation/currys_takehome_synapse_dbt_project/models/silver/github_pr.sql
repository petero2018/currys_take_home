with source_data as (

SELECT
    JSON_VALUE(pr.json_line, '$.number')                AS pr_number,
    JSON_VALUE(pr.json_line, '$.url')                   AS pr_url,
    JSON_VALUE(pr.json_line, '$.title')                 AS pr_title,
    JSON_VALUE(pr.json_line, '$.body')                  AS pr_body,
    JSON_VALUE(pr.json_line, '$.author__login')         AS author_login,
    JSON_VALUE(pr.json_line, '$.author__avatar_url')    AS author_avatar_url,
    JSON_VALUE(pr.json_line, '$.author__url')           AS author_url,
    JSON_VALUE(pr.json_line, '$.author_association')    AS author_association,
    JSON_VALUE(pr.json_line, '$.state')                 AS pr_state,
    JSON_VALUE(pr.json_line, '$.closed')                AS is_closed,
    JSON_VALUE(pr.json_line, '$.created_at')            AS created_at,
    JSON_VALUE(pr.json_line, '$.updated_at')            AS updated_at,
    JSON_VALUE(pr.json_line, '$.closed_at')             AS closed_at,
    JSON_VALUE(pr.json_line, '$.reactions_total_count') AS reactions_total_count,
    JSON_VALUE(pr.json_line, '$.comments_total_count')  AS comments_total_count,
    JSON_VALUE(pr.json_line, '$._dlt_load_id')          AS _dlt_load_id,
    JSON_VALUE(pr.json_line, '$._dlt_id')               AS _dlt_id
FROM OPENROWSET(
        BULK 'https://stcurrysprod.dfs.core.windows.net/currysprodfs/github/petero2018_currys_take_home_pull_requests/pull_requests/',
        FORMAT = 'CSV',
        FIELDTERMINATOR = '0x0b',
        FIELDQUOTE      = '0x0b'
     )
     WITH (json_line nvarchar(max))
     AS pr;

)

select *
from source_data
