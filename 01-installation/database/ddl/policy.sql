drop table if exists policy cascade;

-- 운영정책
create table policy (
	policy_id								integer,
	user_id_min_length						integer				default 5,
	created_date							timestamp with time zone			default now(),
	constraint policy_pk primary key (policy_id)	
);

comment on table policy is '운영정책';
comment on column policy.policy_id is '고유번호';

comment on column policy.user_id_min_length is '사용자 아이디 최소 길이. 기본값 5';
comment on column policy.created_date is '등록일';