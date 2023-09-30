/************************************
  일별 매출액 및 주문 건수
*************************************/
/*orders테이블에는 전반적인 주문정보가 있음 주문일자, 주문처리한 직원id, 배송일자 등
order_items에는 주문한 물건의 id, 수량, 가격, 양, 할인율 등의 정보가 있음*/

select date_trunc('day',a.order_date) ::date as day
      , sum(amount) as sum_amount, count(distinct a.order_id) as daily_ord_cnt /* 1:M관계이기 때문에 distinct 필요)*/
      , b.product_id
from nw.orders a
     join nw.order_items as b on a.order_id = b.order_id
group by date_trunc('day',a.order_date) ::date 
        , b.product_id ;
 /*현재 데이터셋 yyyy-mm-dd형태라서 굳이 date_trunc를 써줄 필요는 없지만,타임스탬프가 찍혔다는 가정하에 사용함, 참고로 Date 와 Timestamp 는 서로 변환이 가능하다*/


/************************************
  주 별 매출액 및 주문 건수
*************************************/
 select date_trunc('week',a.order_date) ::date as week
      , sum(amount) as sum_amount, count(distinct a.order_id) as daily_ord_cnt /* 1:M관계이기 때문에 distinct 필요)*/
      , b.product_id
from nw.orders a
     join nw.order_items as b on a.order_id = b.order_id
group by date_trunc('week',a.order_date) ::date
         , b.product_id ;

/************************************
  월 별 매출액 및 주문 건수
*************************************/
 select date_trunc('month',a.order_date) ::date as month
      , sum(amount) as sum_amount, count(distinct a.order_id) as daily_ord_cnt /* 1:M관계이기 때문에 distinct 필요)*/
      , b.product_id
from nw.orders a
     join nw.order_items as b on a.order_id = b.order_id
group by date_trunc('month',a.order_date) ::date
         , b.product_id ;
   
/************************************
  분기 별 매출액 및 주문 건수
*************************************/
 select date_trunc('quarter',a.order_date) ::date as quarter 
      , sum(amount) as sum_amount, count(distinct a.order_id) as daily_ord_cnt /* 1:M관계이기 때문에 distinct 필요)*/
      , b.product_id
from nw.orders a
     join nw.order_items as b on a.order_id = b.order_id
group by date_trunc('quarter',a.order_date) ::date
        , b.product_id ;
   