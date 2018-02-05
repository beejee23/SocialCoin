/* 
This script was copied into Google BigQuery's Editor to search the reddit_comments database
for cyrptocurrency symbol mentions in comments on the r/cryptocurrency subreddit.

Symbols are typically 3-5 upper case strings, so some cleaning will be needed to
remove strings that aren't actually symbols.

After 2015, the database is broken up by month, so lcoation will need to be changed to 
separately query each month:

i.e. for January 2017:
FROM
              [fh-bigquery:reddit_comments.2017_01]

*/


SELECT
  word,
  s_count,
  s_ratio,
  g_count,
  g_ratio,
  s_to_g_ratio,
  weight
FROM (
  SELECT
    s.word word,
    s.c s_count,
    ROUND(s.ratio,4) s_ratio,
    g.c g_count,
    ROUND(g.ratio,4) g_ratio,
    ROUND(s.ratio/g.ratio,2) s_to_g_ratio,
    ROUND(s.ratio/g.ratio,2) * s.c weight
  FROM (
    SELECT
      c,
      word,
      ssum,
      (c/ssum)*100 ratio
    FROM (
      SELECT
        c,
        word,
        SUM(c) OVER () AS ssum
      FROM (
        SELECT
          COUNT(*) c,
          word
        FROM (
          SELECT
            REGEXP_EXTRACT(word,r'([A-Z\-\']{3,5})') word
          FROM (
            SELECT
              SPLIT(body,' ') word
            FROM
              [fh-bigquery:reddit_comments.2017_01]
            WHERE
              LOWER(subreddit)="cryptocurrency"))
        GROUP BY
          word))) s
  JOIN EACH (
    SELECT
      c,
      word,
      gsum,
      (c/gsum)*100 ratio
    FROM (
      SELECT
        c,
        word,
        SUM(c) OVER () AS gsum
      FROM (
        SELECT
          COUNT(*) c,
          word
        FROM (
          SELECT
            REGEXP_EXTRACT(word,r'([A-Z\-\']{3,5})') word
          FROM (
            SELECT
              SPLIT(body,' ') word
            FROM
              [fh-bigquery:reddit_comments.2017_01]))
        GROUP BY
          word))) g
  ON
    g.word = s.word
  WHERE
    s.word NOT IN ('gt',
      'lt',
      'amp') )
WHERE
  s_count > 10
ORDER BY
  s_count DESC
  