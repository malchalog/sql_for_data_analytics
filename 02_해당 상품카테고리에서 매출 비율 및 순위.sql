
/************************************
상품별 전체 매출액 및 해당 상품 카테고리 전체 매출액 대비 비율, 해당 상품카테고리에서 매출 순위
step 1: 상품별 전체 매출액을 구함
step 2: step 1의 집합에서 상품 카테고리별 전체 매출액을 구하고, 비율과 매출 순위를 계산. 
*************************************/
with
temp_01 as ( 
	select a.product_id, max(product_name) as product_name, max(category_name) as category_name
	      /*group by절에 있지 않은 컬럼을 가져오려면 반드시 집계함수를 써야 하기 때문에 max안에 넣어서 가져올 수 있음  */
		, sum(amount) as sum_amount
	from nw.order_items a
	    inner join nw.products b
			on a.product_id = b.product_id
		inner join nw.categories c /* products 테이블에 product_id : category_id가 1:M으로 연결되어 있다 */
			on b.category_id = c.category_id
	group by a.product_id
)
select product_name, sum_amount as product_sales
	, category_name
	, sum(sum_amount) over (partition by category_name) as category_sales
	, sum_amount / sum(sum_amount) over (partition by category_name) as product_category_ratio
	, row_number() over (partition by category_name order by sum_amount desc) as product_rn
from temp_01
order by category_name, product_sales desc;
		
select *
from nw.products p   