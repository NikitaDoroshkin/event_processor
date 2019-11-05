SELECT time_spent as time, COUNT(*) as users
FROM (
         -- 1. Calculate arrayDifference between dates getting intervals in seconds (rounded)
         -- 2. Choose odd elements, that is (SessionStart, SessionEnd) pairs, not (SessionEnd, SessionStart)
         -- 3. Sum intervals to get full time
      SELECT arraySum(arrayFilter((x, i) -> (modulo(i, 2) == 1),
                                  arrayMap((a, b) -> round((toDateTime(a) - toDateTime(b)) / 60) * 60,
                                           arraySlice(g_time, 2, purchase_idx - 1),
                                           arraySlice(g_time, 1, purchase_idx - 1)) as differences,
                                  arrayEnumerate(differences))) time_spent
      FROM (
            SELECT indexOf(g_name, 'Purchase') as purchase_idx,
                   groupArray(event_time)      as g_time,
                   groupArray(event_name)      as g_name
            FROM (SELECT user_id, event_name, event_time
                  FROM zimad_test.events
                  WHERE toDate(registration_time) >= today() - 100
                  ORDER BY user_id, event_time)
            GROUP BY user_id
                     -- Include users having at least 2 records with first of type SessionStart (can be discussed)
            HAVING COUNT(*) > 1
               and g_name[1] = 'SessionStart'
            ORDER BY user_id
               )
           -- Include users that have made a purchase
      WHERE purchase_idx > 0
         )
GROUP BY time_spent