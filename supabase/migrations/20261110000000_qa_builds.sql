-- QA builds: a push to a branch like ready-for-qa builds for the testers
-- instead of the stores. Android becomes a signed APK posted to Slack
-- (track 'qa'), iOS goes to TestFlight with a note in Slack (track
-- 'qaTestflight'), and the Jira tickets named in the last commit move to
-- "Ready for QA".
--
-- releases.track is free text, so the two tracks need no change here. The
-- two connections are credentials like the others: the token is the
-- secret, meta holds the rest.
--   slack  meta { channel }                          secret { token }
--   jira   meta { site, email, status, projects }    secret { token }
alter table public.credentials drop constraint if exists credentials_kind_check;
alter table public.credentials add constraint credentials_kind_check
  check (kind in ('androidKeystore', 'googlePlayServiceAccount', 'appStoreConnectKey',
                  'buildFile', 'slack', 'jira'));
