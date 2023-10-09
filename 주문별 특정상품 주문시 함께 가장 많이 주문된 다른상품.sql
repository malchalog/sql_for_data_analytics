-- order별 특정 상품 주문시 함께 가장 많이 주문된 다른 상품 추출하기
with 
-- order_items와 order_items를 order_id로 조인하면 M:M 조인되면서 개별 order_id별 주문 상품별로 연관된 주문 상품 집합을 생성
temp_01 as (
select a.order_id
      , a.product_id as prod_01
      , b.product_id as prod_02 
from order_items a
	join order_items b on a.order_id = b.order_id
where a.product_id != b.product_id -- 동일 order_id로 동일 주문상품은 제외
),
-- prod_01 + prod_02 레벨로 group by 건수를 추출. 
temp_02 as (
select prod_01, prod_02, count(*) as cnt
from temp_01 
group by prod_01, prod_02
), 
temp_03 as (
select prod_01, prod_02, cnt
	-- prod_01별로 가장 많은 건수를 가지는 prod_02를 찾기 위해 cnt가 높은 순으로 순위추출. 
    , row_number() over (partition by prod_01 order by cnt desc) as rnum
from temp_02
)
-- 순위가 1인 데이터만 별도 추출. 
select prod_01, prod_02, cnt 
from temp_03
where rnum = 1;


-- 사용자별 특정 상품 주문시 함께 가장 많이 주문된 다른 상품 추출하기
with 
-- user_id는 order_items에 없으므로 order_items와 orders를 조인하여 user_id 추출. 
temp_00 as (
select b.user_id
      ,a.order_id
      ,a.product_id
from order_items a
	join orders b on a.order_id = b.order_id
), 
-- temp_00을 user_id로 셀프 조인하면 M:M 조인되면서 개별 user_id별 주문 상품별로 연관된 주문 상품 집합을 생성
temp_01 as
(
select a.user_id, a.product_id as prod_01, b.product_id as prod_02 
from temp_00 a
	join temp_00 b on a.user_id = b.user_id
where a.product_id != b.product_id
), 
-- prod_01 + prod_02 레벨로 group by 건수를 추출. 
temp_02 as (
select prod_01, prod_02, count(*) as cnt
from temp_01 
group by prod_01, prod_02
), 
temp_03 as (
select prod_01, prod_02, cnt
	-- prod_01별로 가장 많은 건수를 가지는 prod_02를 찾기 위해 cnt가 높은 순으로 순위추출. 
    , row_number() over (partition by prod_01 order by cnt desc) as rnum
from temp_02
)
-- 순위가 1인 데이터만 별도 추출. 
select prod_01, prod_02, cnt, rnum
from temp_03
where rnum = 1
;

select b.user_id, a.* 
from order_items a
join orders b on a.order_id = b.order_id 
where product_id in ('GGOEA0CH077599', 'GGOEYAQB073215')
order by 1, order_id, item_seq;
