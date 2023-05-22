create temp view exporter as

WITH

pre AS (


	select ts, hdr from (
		SELECT ts, hdr, count(1) over (partition by hdr) as c
		FROM pkt
		JOIN capture USING (capture_id)
		WHERE
			capture.name = :'name'
			AND capture."type" = 'pre'
	) as yolo where c = 1

)

, post AS (
	SELECT ts, hdr
	FROM pkt
	JOIN capture USING (capture_id)
	WHERE
		capture.name = :'name'
		AND capture."type" = 'post'
)

SELECT
	post.ts - pre.ts as latency,
	pre.ts AS prets,
	post.ts as postts,
	encode(pre.hdr, 'hex')
FROM  pre JOIN  post USING (hdr)
WHERE post.ts > pre.ts
    AND post.ts < pre.ts + 5 * 1e9
    AND post.ts >= (1000000::bigint * (:'trim_ms')::bigint + (SELECT MIN(ts) from post))::bigint
;

\copy (select latency, prets, postts from exporter order by prets) to pstdout csv header
