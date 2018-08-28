
--1
select fc.v_ext_ident, sum(fsc.n_cost_period) as sum_AP, fd.v_name
from fw_contracts fc
    left join fw_services_cost fsc
    on fsc.id_contract_inst = fc.id_contract_inst
    and fsc.dt_start <= current_timestamp and fsc.dt_stop > current_timestamp
        left join fw_departments fd
        on fd.id_department = fc.id_department 
        and fd.b_deleted = 0
where fc.dt_start <= current_timestamp and fc.dt_stop > current_timestamp
group by fc.v_ext_ident, fd.v_name 


--2
select fd.v_name, avg(table1.sum_AP)
from fw_departments fd
left join (
            select fc.id_contract_inst, sum(fsc.n_cost_period) as sum_AP, fd.id_department
            from fw_contracts fc
                left join fw_services_cost fsc
                on fsc.id_contract_inst = fc.id_contract_inst
                and fsc.dt_start <= current_timestamp and fsc.dt_stop > current_timestamp
                    left join fw_departments fd
                    on fd.id_department = fc.id_department 
                    and fd.b_deleted = 0
            where fc.dt_start <= current_timestamp and fc.dt_stop > current_timestamp
            group by fc.id_contract_inst,fd.id_department) table1
on table1.id_department = fd.id_department
and fd.b_deleted = 0
group by fd.v_name; 


--3. 

--1var
select sum_contr.v_ext_ident, sum_contr.sum_AP 
from 
        (select fd.id_department,avg(table1.sum_AP) as avg_sum_AP 
        from fw_departments fd
        left join (
                    select fc.id_contract_inst, sum(fsc.n_cost_period) as sum_AP, fd.id_department
                    from fw_contracts fc
                        left join fw_services_cost fsc
                        on fsc.id_contract_inst = fc.id_contract_inst
                        and fsc.dt_start <= current_timestamp and fsc.dt_stop > current_timestamp
                            left join fw_departments fd
                            on fd.id_department = fc.id_department 
                            and fd.b_deleted = 0
                    where fc.dt_start <= current_timestamp and fc.dt_stop > current_timestamp
                    group by fc.id_contract_inst,fd.id_department) table1
        on table1.id_department = fd.id_department
        and fd.b_deleted = 0
        group by fd.id_department) avg_dep

left join
        (select fc.v_ext_ident, sum(fsc.n_cost_period) as sum_AP, fd.id_department
        from fw_contracts fc
            left join fw_services_cost fsc
            on fsc.id_contract_inst = fc.id_contract_inst
            and fsc.dt_start <= current_timestamp and fsc.dt_stop > current_timestamp
                left join fw_departments fd
                on fd.id_department = fc.id_department 
                and fd.b_deleted = 0
        where fc.dt_start <= current_timestamp and fc.dt_stop > current_timestamp
        group by fc.v_ext_ident, fd.id_department) sum_contr
        
on avg_dep.id_department = sum_contr.id_department
where sum_contr.sum_AP > avg_dep.avg_sum_AP; 


--2 var
With query_sum_contr AS 
(select fc.v_ext_ident, sum(fsc.n_cost_period) as sum_AP, fd.id_department
        from fw_contracts fc
            left join fw_services_cost fsc
            on fsc.id_contract_inst = fc.id_contract_inst
            and fsc.dt_start <= current_timestamp and fsc.dt_stop > current_timestamp
                left join fw_departments fd
                on fd.id_department = fc.id_department 
                and fd.b_deleted = 0
        where fc.dt_start <= current_timestamp and fc.dt_stop > current_timestamp
        group by fc.v_ext_ident, fd.id_department)

select query_sum_contr.v_ext_ident, query_sum_contr.sum_AP 
from    (select fd.id_department, avg(query_sum_contr.sum_AP) as avg_sum_AP 
        from fw_departments fd
        left join (query_sum_contr)
        on query_sum_contr.id_department = fd.id_department
        and fd.b_deleted = 0
        group by fd.id_department)avg_dep
        
left join (query_sum_contr)
on avg_dep.id_department = query_sum_contr.id_department
where query_sum_contr.sum_AP > avg_dep.avg_sum_AP; 


--4
-- Ne_verno_peredelayu

with query1 as(
select fc.id_contract_inst, fc.id_department, sum(fsc.n_cost_period) as sum_AP
from fw_contracts  fc
    join fw_services_cost fsc
    on fc.id_contract_inst = fsc.id_contract_inst and
    fsc.dt_start <= current_timestamp and current_timestamp < fsc.dt_stop
where fc.dt_start <= current_timestamp and current_timestamp < fc.dt_stop and fc.v_status = 'A'
group by fc.id_contract_inst, fc.id_department)


select fs.v_name as v_service_name, query1.id_department, sum(query1.sum_AP) as total_sumAP_of_service
from query1
        
join (select query1.id_department, avg(query1.sum_AP) as f_avg_cost
        from query1
        group by query1.id_department) table1
        on query1.id_department = table1.id_department and query1.sum_AP > table1.f_avg_cost
    
join fw_services fss
on fss.dt_start <= current_timestamp 
and current_timestamp < fss.dt_stop 
and fss.b_deleted = 0 
and fss.v_status = 'A' 
and query1.id_contract_inst = fss.id_contract_inst

join fw_service fs
on fs.b_deleted = 0 
and fss.id_service = fs.id_service
group by fs.v_name, query1.id_department;





--5. 

select fc.v_ext_ident,fc.id_contract_inst, table1.number_of_changes 
from fw_contracts fc
left join (select id_contract_inst, count(*) as number_of_changes
            from fw_services_cost fsc
            where fsc.dt_start <= current_timestamp 
            and fsc.dt_stop > current_timestamp            
            group by id_contract_inst)table1
on  table1.id_contract_inst = fc.id_contract_inst
where  fc.dt_start <= current_timestamp and fc.dt_stop > current_timestamp and fc.v_status = 'A'
and 2 <= (table1.number_of_changes)     


--6. 
-- Ne_verno_peredelayu

select fd.v_name,table2.v_name, max(table2.sum_AP)
from fw_departments fd
 join (select table1.id_department, tp.v_name, table1.sum_AP
           from
            (select fc.id_contract_inst,fsc.id_service_inst,fss.id_tariff_plan, sum(fsc.n_cost_period) as sum_AP, fd.id_department 
            from fw_contracts fc
                left join fw_services_cost fsc
                on fsc.id_contract_inst = fc.id_contract_inst
                and fsc.dt_start <= current_timestamp and fsc.dt_stop > current_timestamp
                 left join fw_departments fd
                    on fd.id_department = fc.id_department 
                    and fd.b_deleted = 0
                        join FW_SERVICES fss
                        on fss.id_contract_inst = fsc.id_contract_inst and fss.id_service_inst = fsc.id_service_inst
                        and fss.dt_start <= current_timestamp and fss.dt_stop > current_timestamp
                        and fss.b_deleted = 0 and fss.v_status = 'A'
                            join FW_SERVICE fs
                            on fs.id_service = fss.id_service
                            and fs.b_add_service = 1 and fs.b_deleted = 0           
where fc.dt_start <= current_timestamp and fc.dt_stop > current_timestamp
group by fc.id_contract_inst,fsc.id_service_inst,fss.id_tariff_plan, fd.id_department) table1
                
join FW_TARIFF_PLAN tp
on  table1.id_tariff_plan = tp.id_tariff_plan 
and tp.dt_start <= current_timestamp and tp.dt_stop > current_timestamp
and tp.b_active = 1
and tp.b_deleted = 0) table2
            
on table2.id_department = fd.id_department
and fd.b_deleted = 0            
group by fd.v_name, table2.v_name;    




