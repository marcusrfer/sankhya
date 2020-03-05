<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="UTF-8" isELIgnored ="false"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<%@ page import="java.util.*" %>
<%@ taglib uri="http://java.sun.com/jstl/core_rt" prefix="c" %>
<%@ taglib prefix="snk" uri="/WEB-INF/tld/sankhyaUtil.tld" %>
<html>
<head>
	<title>Acompanhamento de Visitas de Contratação</title>
    <link rel="stylesheet" type="text/css" href="${BASE_FOLDER}/css/tablevisitas.css">
	<snk:load/>
</head>
<body>
	<h2>Visitas</h2>
	<snk:query var="visitas">
     select t.nomevisitado, 
        t.dhprevis, 
        t.dhvisita,
       ad_get.opcoescampo(t.status, 'STATUS', 'AD_TSFAVS') status,
       initcap(app.nomeusu) entrevistador,
        t.codpesquisa
      from ad_tsfavs t
      left join ad_appssapesquisa app
        on app.codusuapp = t.codusuapp
     where 1 = 1
       and t.tipovisita = 'C'
    </snk:query>
   <table class="table">
       <thead class="header">
     <tr>
         <th>Nome</th>
         <th>Dt. Prevista</th>
         <th>Dt. Visita</th>
         <th>Situação</th>
         <th>Entrevistador</th>
    </tr>
        </thead>
     <tbody class="tbody">
    <c:forEach items="${visitas.rows}" var="row">
     <tr>
        <td><c:out value="${row.nomevisitado}"/></td> 
        <td><c:out value="${row.dhprevis}" /></td>
         <td><c:out value="${row.dhvisita}" /></td>
         <td><c:out value="${row.status}" /></td>
         <td><c:out value="${row.entrevistador}" /></td>
    </tr>   
<!--
      <tr>
        <td>João</td> 
        <td>01/10/2019</td>
        <td>03/10/2019</td>
        <td>Finalizada</td>
        <td>Fulano</td>
    </tr>   
-->
    </c:forEach>
        </tbody>
    </table>	
</body>
</html>