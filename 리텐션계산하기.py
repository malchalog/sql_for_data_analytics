# 리텐션 SQL로 계산하기

#일반적으로 잔존율은 특정일을 기준으로 시간의 흐름에 따른 사용자의 재방문 횟수로 잔존율을 나타냄과 동시에 기준일 또한 이동시키면서 서비스 런칭 이후의 시간의 흐름에 따른 잔존율도 함께 표시함

잔존율은 일/주/월별 잔존율 등으로 나타낼 수 있으며, 보통 게임업계의 경우 일별 잔존율, 쇼핑몰의 경우 주별/월별 잔존율 선호

## 01. 일주일간 일별 잔존율 SQL로 구하기

### Step1 일시 → 일자로 변환 후 user_id + 생성일자 + 접속일자로 group by

- postgreSQL코드
    
    ```sql
    /************************************
    사용자 생성 날짜 별 일주일간 잔존율(Retention rate) 구하기
    *************************************/
    
    # Step1. 접속 일시 → 일자로 변환 후 user_id + 생성일자 + 접속일자로 group by
    with temp_01 as (
    	select a.user_id
            , date_trunc('day', a.create_time)::date as user_create_date -- 생성일자 
            , date_trunc('day', b.visit_stime)::date as sess_visit_date -- 접속일자
    		    , count(*) cnt
    	from ga_users a
    		   left join ga_sess b on a.user_id = b.user_id
    	where  create_time >= (:current_date - interval '8 days') and create_time < :current_date -- 오늘을 기준으로 일주일 전
    	group by 1,2,3
    ```
    
- mySQL코드
    
    ```sql
    # Step1. 접속 일시 → 일자로 변환 후 user_id + 생성일자 + 접속일자로 group by
    with temp_01 as (
    	select a.user_id
            , DATE_FORMAT(a.create_time,'%Y-%m-%d') as user_create_date -- 생성일자 
            , DATE_FORMAT(b.visit_stime,'%Y-%m-%d') as sess_visit_date -- 접속일자
    		    , count(*) cnt
    	from ga_users a
    		   left join ga_sess b on a.user_id = b.user_id
    	where  create_time BETWEEN DATE_ADD (NOW(), INTERVAL -1 WEEK) AND NOW()-- 오늘을 기준으로 일주일 전
    	group by 1,2,3
    ```
    
    ![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/a2304ec8-dfea-40c3-b856-17f82aa9a38d/557411cf-ac52-4181-ab1d-c5733aa47714/Untitled.png)
    

### Step2. 생성일자로 Group by 해서 접속일자가 생성일자보다 +1 ~ +7인 사용자 수 구하기

- postgreSQL, MySQL코드
    
    ```sql
    # Step1. 접속 일시 → 일자로 변환 후 user_id + 생성일자 + 접속일자로 group by
    with temp_01 as (
    	select a.user_id
            , DATE_FORMAT(a.create_time,'%Y-%m-%d') as user_create_date -- 생성일자 
            , DATE_FORMAT(b.visit_stime,'%Y-%m-%d') as sess_visit_date -- 접속일자
    		    , count(*) cnt
    	from ga_users a
    		   left join ga_sess b on a.user_id = b.user_id
    	where  create_time BETWEEN DATE_ADD (NOW(), INTERVAL -1 WEEK) AND NOW()-- 오늘을 기준으로 일주일 전
    	group by 1,2,3
    
    ,temp_02 as (
    select user_create_date, count(*) as create_cnt
    	-- d1 에서 d7 일자별 접속 사용자 건수 구하기. 
    	, sum(case when sess_visit_date = user_create_date + interval '1 day' then 1 else NULL end ) as d1_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '2 day' then 1 else NULL end) as d2_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '3 day' then 1 else NULL end) as d3_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '4 day' then 1 else NULL end) as d4_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '5 day' then 1 else NULL end) as d5_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '6 day' then 1 else NULL end) as d6_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '7 day' then 1 else NULL end) as d7_cnt
    from temp_01 
    group by user_create_date
    )
    ```
    
    ![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/a2304ec8-dfea-40c3-b856-17f82aa9a38d/bd1497f6-fa0f-4219-b1e9-2629ced59880/Untitled.png)
    

## 02. 월별 잔존율 및 특정 채널별 잔존율 SQL로 구하기

- PostgreSQL
    
    ```sql
    
    with temp_01 as (
    	select a.user_id, date_trunc('week', a.create_time)::date as user_create_date
             ,  date_trunc('week', b.visit_stime)::date as sess_visit_date
    		, count(*) cnt
    	from ga_users a
    		left join ga_sess b
    			on a.user_id = b.user_id
    	--where  create_time >= (:current_date - interval '7 weeks') and create_time < :current_date
    	where create_time >= to_date('20160912', 'yyyymmdd') and create_time < to_date('20161101', 'yyyymmdd')
    	group by a.user_id, date_trunc('week', a.create_time)::date, date_trunc('week', b.visit_stime)::date
    ), 
    temp_02 as (
    select user_create_date, count(*) as create_cnt
         -- w1 에서 w7까지 주단위 접속 사용자 건수 구하기.
    	, sum(case when sess_visit_date = user_create_date + interval '1 week' then 1 else null end ) as w1_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '2 week' then 1 else null end) as w2_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '3 week' then 1 else null end) as w3_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '4 week' then 1 else null end) as w4_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '5 week' then 1 else null end) as w5_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '6 week' then 1 else null end) as w6_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '7 week' then 1 else null end) as w7_cnt
    from temp_01 
    group by user_create_date
    )
    select user_create_date, create_cnt
        -- w1 에서 w7 주별 잔존율 구하기.
    	, round(100.0 * w1_cnt/create_cnt, 2) as w1_ratio
    	, round(100.0 * w2_cnt/create_cnt, 2) as w2_ratio
    	, round(100.0 * w3_cnt/create_cnt, 2) as w3_ratio
    	, round(100.0 * w4_cnt/create_cnt, 2) as w4_ratio
    	, round(100.0 * w5_cnt/create_cnt, 2) as w5_ratio
    	, round(100.0 * w6_cnt/create_cnt, 2) as w6_ratio
    	, round(100.0 * w7_cnt/create_cnt, 2) as w7_ratio
    ```
    

### Step1)  테이블 조인 후 가입일, 날짜 데이터를 ‘YYYY-MM-01’ 형태로 가공

- MYSQL
    
    ```sql
    -- STEP1 첫 주문일, 주문날짜 데이터를 ‘YYYY-MM-01’ 형태로 가공
    WITH records_preprocessed AS (
        SELECT r.customer_id
             , DATE_FORMAT(c.first_order_date, '%Y-%m-01') first_create_month
             , DATE_FORMAT(r.order_date, '%Y-%m-01') AS visit_month
        FROM records r
             INNER JOIN customer_stats c ON r.customer_id = c.customer_id
    )
    ```
    

### Step2) 위 데이터를 사용하여 각 월 별로 첫 구매한 고객이 몇 명인지 계산

- MYSQL
    
    ```sql
    WITH records_preprocessed AS (
        SELECT r.customer_id
             , DATE_FORMAT(c.create_date, '%Y-%m-01') first_order_month
             , DATE_FORMAT(r.visit_date, '%Y-%m-01') order_month
        FROM records r
             INNER JOIN customer_stats c ON r.customer_id = c.customer_id
    )
    
    SELECT first_order_month
         , COUNT(DISTINCT customer_id) AS user_create_month
         , COUNT(DISTINCT CASE WHEN DATE_ADD(create_month, INTERVAL 1 MONTH) = visit_month THEN customer_id END) AS month1
         -- sum(case when sess_visit_date = user_create_date + interval '1 week' then 1 else null end ) as w1_cnt
    FROM records_preprocessed
    GROUP BY 1
    ```
    

## 03. 일주일간 생성된 사용자에 대해 특정 채널별 잔존율 SQL로 구하기

- postgreSQL
    
    ```sql
    with temp_01 as (
    	select a.user_id, channel_grouping
    		, date_trunc('week', a.create_time)::date as user_create_date,  date_trunc('week', b.visit_stime)::date as sess_visit_date
    		, count(*) cnt
    	from ga_users a
    		left join ga_sess b
    			on a.user_id = b.user_id
    	where  create_time >= to_date('20160912', 'yyyymmdd') and create_time < to_date('20160919', 'yyyymmdd')
    	--and channel_grouping='Referral' -- Social Organic Search, Direct, Referral
    	group by a.user_id, channel_grouping, date_trunc('week', a.create_time)::date, date_trunc('week', b.visit_stime)::date
    ), 
    temp_02 as (
    select user_create_date, channel_grouping, count(*) as create_cnt
         -- w1 에서 w7까지 주단위 접속 사용자 건수 구하기.
    	, sum(case when sess_visit_date = user_create_date + interval '1 week' then 1 else null end ) as w1_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '2 week' then 1 else null end) as w2_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '3 week' then 1 else null end) as w3_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '4 week' then 1 else null end) as w4_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '5 week' then 1 else null end) as w5_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '6 week' then 1 else null end) as w6_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '7 week' then 1 else null end) as w7_cnt
    from temp_01 
    group by user_create_date, channel_grouping)
    
    select user_create_date, channel_grouping, create_cnt
        -- w1 에서 w7 주별 잔존율 구하기
    	, round(100.0 * w1_cnt/create_cnt, 2) as w1_ratio
    	, round(100.0 * w2_cnt/create_cnt, 2) as w2_ratio
    	, round(100.0 * w3_cnt/create_cnt, 2) as w3_ratio
    	, round(100.0 * w4_cnt/create_cnt, 2) as w4_ratio
    	, round(100.0 * w5_cnt/create_cnt, 2) as w5_ratio
    	, round(100.0 * w6_cnt/create_cnt, 2) as w6_ratio
    	, round(100.0 * w7_cnt/create_cnt, 2) as w7_ratio
    from temp_02 order by 3 desc;
    ```
    
- mySQL
    
    ```sql
    # Step1. 접속 일시 → 일자로 변환 후 user_id + 생성일자 + 접속일자로 group by
    with temp_01 as (
    	select a.user_id
            , channel_grouping
            , DATE_FORMAT(a.create_time,'%Y-%m-%d') as user_create_date -- 생성일자 
            , DATE_FORMAT(b.visit_stime,'%Y-%m-%d') as sess_visit_date -- 접속일자
    		    , count(*) cnt
    	from ga_users a
    		   left join ga_sess b on a.user_id = b.user_id
    	where  create_time BETWEEN DATE_ADD (NOW(), INTERVAL -1 WEEK) AND NOW()-- 오늘을 기준으로 일주일 전
    	group by 1,2,3,4
    
    ,temp_02 as (
    select user_create_date
          ,channel_grouping
          ,count(*) as create_cnt
    	-- d1 에서 d7 일자별 접속 사용자 건수 구하기. 
    	, sum(case when sess_visit_date = user_create_date + interval '1 day' then 1 else NULL end ) as d1_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '2 day' then 1 else NULL end) as d2_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '3 day' then 1 else NULL end) as d3_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '4 day' then 1 else NULL end) as d4_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '5 day' then 1 else NULL end) as d5_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '6 day' then 1 else NULL end) as d6_cnt
    	, sum(case when sess_visit_date = user_create_date + interval '7 day' then 1 else NULL end) as d7_cnt
    from temp_01 
    group by user_create_date, channel_grouping
    )
    
    select user_create_date, channel_grouping, create_cnt
        -- w1 에서 w7 주별 잔존율 구하기
    	, round(100.0 * w1_cnt/create_cnt, 2) as w1_ratio
    	, round(100.0 * w2_cnt/create_cnt, 2) as w2_ratio
    	, round(100.0 * w3_cnt/create_cnt, 2) as w3_ratio
    	, round(100.0 * w4_cnt/create_cnt, 2) as w4_ratio
    	, round(100.0 * w5_cnt/create_cnt, 2) as w5_ratio
    	, round(100.0 * w6_cnt/create_cnt, 2) as w6_ratio
    	, round(100.0 * w7_cnt/create_cnt, 2) as w7_ratio
    from temp_02 order by 3 desc;
    ```
    
    ![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/a2304ec8-dfea-40c3-b856-17f82aa9a38d/4428390f-5593-404a-b0f5-23d6de6216f1/Untitled.png)
    

## 04 채널별 리텐션과 총 리텐션 SQL로 구하기 (UNION ALL)

- postgreSQL