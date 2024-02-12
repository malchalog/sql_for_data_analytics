/**********************************************
 전체 매출 전환율 및 일별, 월별 매출 전환율과 매출액
***********************************************/
/* 
   Unknown = 0. (홈페이지)
   Click through of product lists = 1, (상품 목록 선택)
   Product detail views = 2, (상품 상세 선택)
   Add product(s) to cart = 3, (카트에 상품 추가)
   Remove product(s) from cart = 4, (카트에서 상품 제거)
   Check out = 5, (결재 시작)
   Completed purchase = 6, (구매 완료)
   Refund of purchase = 7, (환불)
   Checkout options = 8 (결재 옵션 선택)
   
   이 중 1, 3, 4가 주로 EVENT로 발생. 0, 2, 5, 6은 주로 PAGE로 발생. 
 *
 **/

-- action_type별 hit_type에 따른 건수
select action_type, count(*) action_cnt
	, sum(case when hit_type='PAGE' then 1 else 0 end) as page_action_cnt
	, sum(case when hit_type='EVENT' then 1 else 0 end) as event_action_cnt
from ga.ga_sess_hits
group by action_type
;

-- 전체 매출 전환율
with 
temp_01 as ( 
select count(distinct sess_id) as purchase_sess_cnt
from ga.ga_sess_hits
where action_type = '6'
),
temp_02 as ( 
select count(distinct sess_id) as sess_cnt
from ga.ga_sess_hits
)
select a.purchase_sess_cnt, b.sess_cnt, 100.0* a.purchase_sess_cnt/sess_cnt as sale_cv_rate
from temp_01 a 
	cross join temp_02 b
;


-- 과거 1주일간 매출 전환률
with 
temp_01 as ( 
select count(distinct a.sess_id) as purchase_sess_cnt
from ga.ga_sess_hits a
	join ga.ga_sess b on a.sess_id = b.sess_id
where a.action_type = '6'
and b.visit_stime >= (:current_date - interval '7 days') and b.visit_stime < :current_date
),
temp_02 as ( 
select count(distinct a.sess_id) as sess_cnt
from ga.ga_sess_hits a
	join ga.ga_sess b on a.sess_id = b.sess_id
and b.visit_stime >= (:current_date - interval '7 days') and b.visit_stime < :current_date
)
select a.purchase_sess_cnt, b.sess_cnt, 100.0* a.purchase_sess_cnt/sess_cnt as sale_cv_rate
from temp_01 a 
	cross join temp_02 b
;


-- 과거 1주일간 일별 매출 전환률 - 01
with 
temp_01 as ( 
select date_trunc('day', b.visit_stime)::date as cv_day, count(distinct a.sess_id) as purchase_sess_cnt
from ga.ga_sess_hits a
	join ga.ga_sess b on a.sess_id = b.sess_id
where a.action_type = '6'
and b.visit_stime >= (:current_date - interval '7 days') and b.visit_stime < :current_date
group by date_trunc('day', b.visit_stime)::date
), 
temp_02 as ( 
select date_trunc('day', b.visit_stime)::date as cv_day, count(distinct a.sess_id) as sess_cnt
from ga.ga_sess_hits a
	join ga.ga_sess b on a.sess_id = b.sess_id
where b.visit_stime >= (:current_date - interval '7 days') and b.visit_stime < :current_date
group by date_trunc('day', b.visit_stime)::date
)
select a.cv_day, a.purchase_sess_cnt, b.sess_cnt, 100.0* a.purchase_sess_cnt/sess_cnt as sale_cv_rate
from temp_01 a 
	join temp_02 b on a.cv_day = b.cv_day
;

-- 과거 1주일간 일별 매출 전환률 - 02
with 
temp_01 as ( 
select date_trunc('day', b.visit_stime)::date as cv_day
	, count(distinct a.sess_id) as sess_cnt
	, count(distinct case when a.action_type = '6' then a.sess_id end) as purchase_sess_cnt
from ga.ga_sess_hits a
	join ga.ga_sess b on a.sess_id = b.sess_id
and b.visit_stime >= (:current_date - interval '7 days') and b.visit_stime < :current_date
group by date_trunc('day', b.visit_stime)::date
)
select a.cv_day, purchase_sess_cnt, sess_cnt, 100.0* purchase_sess_cnt/sess_cnt as sale_cv_rate
from temp_01 a 
;

-- 과거 1주일간 일별 매출 전환률 및 매출액
with 
temp_01 as ( 
select date_trunc('day', b.visit_stime)::date as cv_day
	, count(distinct a.sess_id) as sess_cnt
	, count(distinct case when a.action_type = '6' then a.sess_id end) as purchase_sess_cnt
from ga.ga_sess_hits a
	join ga.ga_sess b on a.sess_id = b.sess_id
and b.visit_stime >= (:current_date - interval '7 days') and b.visit_stime < :current_date
group by date_trunc('day', b.visit_stime)::date
),
temp_02 as ( 
select date_trunc('day', a.order_time)::date as ord_day
	, sum(prod_revenue) as sum_revenue
from ga.orders a
	join ga.order_items b on a.order_id = b.order_id
where a.order_time >= (:current_date - interval '7 days') and a.order_time < :current_date 
group by date_trunc('day', a.order_time)::date
)
select a.cv_day, b.ord_day, a.sess_cnt, a.purchase_sess_cnt, 100.0* purchase_sess_cnt/sess_cnt as sale_cv_rate
	, b.sum_revenue, b.sum_revenue/a.purchase_sess_cnt as revenue_per_purchase_sess
from temp_01 a
	left join temp_02 b on a.cv_day = b.ord_day
;

	
-- 월별 매출 전환률과 매출액
with 
temp_01 as ( 
select date_trunc('month', b.visit_stime)::date as cv_month
	, count(distinct a.sess_id) as sess_cnt
	, count(distinct case when a.action_type = '6' then a.sess_id end) as purchase_sess_cnt
from ga.ga_sess_hits a
	join ga.ga_sess b on a.sess_id = b.sess_id
group by date_trunc('month', b.visit_stime)::date
),
temp_02 as ( 
select date_trunc('month', a.order_time)::date as ord_month
	, sum(prod_revenue) as sum_revenue
from ga.orders a
	join ga.order_items b on a.order_id = b.order_id 
group by date_trunc('month', a.order_time)::date
)
select a.cv_month, b.ord_month, a.sess_cnt, a.purchase_sess_cnt, 100.0* purchase_sess_cnt/sess_cnt as sale_cv_rate
	, b.sum_revenue, b.sum_revenue/a.purchase_sess_cnt as revenue_per_purchase_sess
from temp_01 a
	left join temp_02 b on a.cv_month = b.ord_month
;

/************************************
채널별 월별 매출 전환율
*************************************/
with 
temp_01 as ( 
select b.channel_grouping, date_trunc('month', b.visit_stime)::date as cv_month
	, count(distinct a.sess_id) as sess_cnt
	, count(distinct case when a.action_type='6' then a.sess_id end) as pur_sess_cnt
from ga.ga_sess_hits a
	join ga.ga_sess b on a.sess_id = b.sess_id
group by b.channel_grouping, date_trunc('month', b.visit_stime)::date
),
temp_02 as (
select a.channel_grouping, date_trunc('month', b.order_time)::date as ord_month
	, sum(prod_revenue) as sum_revenue
from ga.ga_sess a 
	join ga.orders b on a.sess_id = b.sess_id 
	join ga.order_items c on b.order_id = c.order_id
group by a.channel_grouping, date_trunc('month', b.order_time)::date
)
select a.channel_grouping, a.cv_month, a.pur_sess_cnt, a.sess_cnt
	, round(100.0* pur_sess_cnt/sess_cnt, 2) as sale_cv_rate
	, b.ord_month, round(b.sum_revenue::numeric, 2) as sum_revenue
	, round(b.sum_revenue::numeric/pur_sess_cnt, 2) as rev_per_pur_sess
from temp_01 a
	left join temp_02 b on a.channel_grouping = b.channel_grouping and a.cv_month = b.ord_month
order by 1, 2
;

/************************************
 월별 신규 사용자의 매출 전환율
*************************************/

-- 월별 신규 사용자 건수 
with 
temp_01 as (
select a.sess_id, a.user_id, a.visit_stime, b.create_time
	, case when date_trunc('day', b.create_time)::date >= date_trunc('month', visit_stime)::date 
	       and date_trunc('day', b.create_time)::date < date_trunc('month', visit_stime)::date + interval '1 month'
	  then 1 else 0 end as is_monthly_new_user
from ga.ga_sess a
	join ga.ga_users b on a.user_id = b.user_id
)
select date_trunc('month', visit_stime)::date, count(*) as sess_cnt
	, count(distinct user_id) as user_cnt
	, sum(case when is_monthly_new_user = 1 then 1 end) as new_user_sess_cnt
	, count(distinct case when is_monthly_new_user = 1 then user_id end) as new_user_cnt
from temp_01 
group by date_trunc('month', visit_stime)::date;

-- 월별 신규 사용자의 매출 전환율 - 01
with 
temp_01 as (
select a.sess_id, a.user_id, a.visit_stime, b.create_time
	, case when date_trunc('day', b.create_time)::date >= date_trunc('month', visit_stime)::date 
	       and date_trunc('day', b.create_time)::date < date_trunc('month', visit_stime)::date + interval '1 month'
	  then 1 else 0 end as is_monthly_new_user
from ga.ga_sess a
	join ga.ga_users b on a.user_id = b.user_id
),
-- 매출 전환한 월별 신규 생성자 세션 건수
temp_02 as (
select date_trunc('month', a.visit_stime)::date as cv_month, count(distinct b.sess_id) as purchase_sess_cnt
from temp_01 a
	join ga.ga_sess_hits b on a.sess_id = b.sess_id
where a.is_monthly_new_user = 1
and b.action_type = '6'
group by date_trunc('month', a.visit_stime)::date
),
-- 월별 신규 생성자 세션 건수
temp_03 as (
select date_trunc('month', visit_stime)::date as cv_month
	, sum(case when is_monthly_new_user = 1 then 1 else 0 end) as monthly_nuser_sess_cnt
from temp_01
group by date_trunc('month', visit_stime)::date
)
select a.cv_month, a.purchase_sess_cnt, b.monthly_nuser_sess_cnt
	, 100.0 * a.purchase_sess_cnt/b.monthly_nuser_sess_cnt as sale_cv_rate
from temp_02 a
	join temp_03 b on a.cv_month = b.cv_month
order by 1;

-- 월별 신규 사용자의 매출 전환율 - 02
-- 매출 전환한 월별 신규 생성자 세션 건수와 월별 신규 생성자 세션 건수를 같이 구함.
with 
temp_01 as (
select a.sess_id, a.user_id, a.visit_stime, b.create_time
	, case when date_trunc('day', b.create_time)::date >= date_trunc('month', visit_stime)::date 
	       and date_trunc('day', b.create_time)::date < date_trunc('month', visit_stime)::date + interval '1 month'
	  then 1 else 0 end as is_monthly_new_user
from ga.ga_sess a
	join ga.ga_users b on a.user_id = b.user_id
),
-- 매출 전환한 월별 신규 생성자 세션 건수와 월별 신규 생성자 세션 건수를 같이 구함. 
temp_02 as (
select date_trunc('month', a.visit_stime)::date as cv_month
	, count(distinct case when is_monthly_new_user = 1 and b.action_type = '6' then b.sess_id end ) as purchase_sess_cnt
	, count(distinct case when is_monthly_new_user = 1 then b.sess_id end ) as monthly_nuser_sess_cnt
from temp_01 a
	join ga.ga_sess_hits b on a.sess_id = b.sess_id
group by date_trunc('month', a.visit_stime)::date
)
select a.cv_month, a.purchase_sess_cnt, a.monthly_nuser_sess_cnt
	, 100.0 * a.purchase_sess_cnt/a.monthly_nuser_sess_cnt as sale_cv_rate
from temp_02 a
order by 1;

/************************************
 전환 퍼널(conversion funnel) 구하기
*************************************/
/* 
   Unknown = 0. (홈페이지)
   Click through of product lists = 1, (상품 목록 선택)
   Product detail views = 2, (상품 상세 선택)
   Add product(s) to cart = 3, (카트에 상품 추가)
   Remove product(s) from cart = 4, (카트에서 상품 제거)
   Check out = 5, (결재 시작)
   Completed purchase = 6, (구매 완료)
   Refund of purchase = 7, (환불)
   Checkout options = 8 (결재 옵션 선택)
   
   이 중 1, 3, 4가 주로 EVENT로 발생. 0, 2, 5, 6은 주로 PAGE로 발생. 
 *
 **/

select * from ga.ga_sess_hits
where sess_id = 'S0213506'
order by hit_seq;

-- 1주일간 세션 히트 데이터에서 세션별로 action_type의 중복 hit를 제거하고 세션별 고유한 action_type만 추출
drop table if exists ga.temp_funnel_base;

create table ga.temp_funnel_base
as
select * 
from (
	select a.*, b.visit_stime, b.channel_grouping 
		, row_number() over (partition by a.sess_id, action_type order by hit_seq) as action_seq
	from ga.ga_sess_hits a
		join ga.ga_sess b on a.sess_id = b.sess_id
	where visit_stime >= (to_date('2016-10-31', 'yyyy-mm-dd') - interval '7 days') and visit_stime < to_date('2016-10-31', 'yyyy-mm-dd')
	) a where a.action_seq = 1
;