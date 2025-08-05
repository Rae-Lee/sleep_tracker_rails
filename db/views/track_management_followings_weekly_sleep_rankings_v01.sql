SELECT
  f.follower_id,
  sr.user_id AS followed_id,
  u.name AS followed_name,
  sr.sleep_at AS sleep_at_utc,
  sr.wake_at AS wake_at_utc,
  sr.sleep_at AT TIME ZONE sr.sleep_timezone AS sleep_at_local,
  sr.wake_at AT TIME ZONE sr.wake_timezone AS wake_at_local,
  sr.sleep_timezone,
  sr.wake_timezone,
  sr.duration
FROM relationship_follow_records f
JOIN track_management_sleep_records sr
  ON sr.user_id = f.followed_id
JOIN master_data_users u 
  ON u.id = sr.user_id
WHERE 
  (sr.sleep_at AT TIME ZONE sr.sleep_timezone) >= date_trunc('week', (NOW() AT TIME ZONE sr.sleep_timezone)) - INTERVAL '1 week'
  AND (sr.sleep_at AT TIME ZONE sr.sleep_timezone) < date_trunc('week', (NOW() AT TIME ZONE sr.sleep_timezone))
  AND sr.wake_at IS NOT NULL
ORDER BY sr.duration DESC;
