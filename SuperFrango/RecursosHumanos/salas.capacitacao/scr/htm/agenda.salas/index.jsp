<!--Desenvolvido por Danilo Ferreira Adorno-->
<!DOCTYPE html>
<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ page import="java.util.*" %>
<%@ page import="java.sql.*" %>
<%@ page import="oracle.sql.*" %>
<%@ page import="java.io.*" %>

<%@ taglib uri="http://java.sun.com/jstl/core_rt" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="/WEB-INF/tld/sankhyaUtil.tld" prefix="snk" %>

<html lang="pt-br" ng-app="app">

<head>

    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Agenda de Reserva de Salas</title>

     <!-- styles -->
    <link rel="stylesheet" href="${BASE_FOLDER}/css/bootstrap.css">
    <link rel="stylesheet" href="${BASE_FOLDER}/css/style.css">
    <link rel="stylesheet" href="${BASE_FOLDER}/font-awesome/css/font-awesome.css">
    <link rel="stylesheet" href="${BASE_FOLDER}/css/ag-grid.css">
    <link rel="stylesheet" href="${BASE_FOLDER}/css/ag-theme-material.css">
    <link rel="stylesheet" href="${BASE_FOLDER}/css/normalize.css">
    <link rel="stylesheet" href="${BASE_FOLDER}/css/materialdesignicons/materialdesignicons.min.css">
    <link rel="stylesheet" href="${BASE_FOLDER}/css/materialPreloader.min.css">
    
    <link rel="stylesheet" href="${BASE_FOLDER}/css/fullcalendar/core/main.min.css">
    <link rel="stylesheet" href="${BASE_FOLDER}/css/fullcalendar/daygrid/main.min.css">
    <link rel="stylesheet" href="${BASE_FOLDER}/css/fullcalendar/timegrid/main.min.css">
    <link rel="stylesheet" href="${BASE_FOLDER}/css/fullcalendar/list/main.min.css">
    <link rel="stylesheet" href="${BASE_FOLDER}/css/fullcalendar/bootstrap/main.min.css">

    <!-- scrips -->
    <script src="${BASE_FOLDER}/js/angular.js"></script>
    <script src="${BASE_FOLDER}/js/ag-grid-enterprise.js"></script>
    <script src="${BASE_FOLDER}/js/date.format.js"></script>
    <script src="${BASE_FOLDER}/js/Chart.js"></script>
    <script src="${BASE_FOLDER}/js/angular-chart.js"></script>
    <script src="${BASE_FOLDER}/js/chartjs-plugin-datalabels.min.js"></script>
    <script src="${BASE_FOLDER}/js/jquery-3.4.1.js"></script>
    <script src="${BASE_FOLDER}/js/popper.min.js"></script>
    <script src="${BASE_FOLDER}/js/bootstrap.js"></script>
    <script src="${BASE_FOLDER}/js/materialPreloader.min.js"></script>
    <script src="${BASE_FOLDER}/js/mask.min.js"></script>
    
    <script src="${BASE_FOLDER}/js/fullcalendar/core/main.min.js"></script>
    <script src="${BASE_FOLDER}/js/fullcalendar/daygrid/main.min.js"></script>
    <script src="${BASE_FOLDER}/js/fullcalendar/timegrid/main.min.js"></script>
    <script src="${BASE_FOLDER}/js/fullcalendar/list/main.min.js"></script>
    <script src="${BASE_FOLDER}/js/fullcalendar/bootstrap/main.min.js"></script>
    <script src="${BASE_FOLDER}/js/fullcalendar/locales-all.min.js"></script>
    
    
    <script src="https://unpkg.com/popper.js@1"></script>
<script src="https://unpkg.com/tippy.js@5"></script>
    
    
    <snk:load />
    
</head>

<body>
<div ng-controller="mController">
    <div class="container-scroller" id="content">
        <div class="container-fluid page-body-wrapper">
            <div class="main-panel">
                <div class="content-wrapper">
                    <div class="row">
                        <div class="col-md-12 grid-margin stretch-card">
                            <div class="card" ng-style="{'margin-top' : isLoading ? '4px' : '0px', 'padding-top' : isLoading ? '0px' : '4px'}">
                                <div class="card-body">
                                    

                                    <div class="row">
                                        <div class="col-md-4">
                                            
                                            <h4 class="card-title"><i class="mdi mdi-file-document-box-outline" style="padding-right: 8px;"></i>Agenda de Reserva de Salas</h4>
                                            
                                            <div class="input-group" style="padding-bottom: 16px; padding-top: 32px;">
                                                <input type="text" class="form-control" placeholder="Buscar Reservas" ng-model="searchText" style="cursor: pointer;">
                                                <div class="input-group-append bg-primary border-primary">
                                                    <button class="btn btn-primary btn-block" ng-click="addReserva()"><i class="mdi mdi-plus"></i> Add Reserva</button>
                                                </div>
                                            </div>

                                            <!--Percorrendo a lista de valores-->
                                            <div class="pre-scrollable" style="max-height: 700px;">
                                                <ul class="bullet-line-list">
                                                    <div ng-repeat="row in data | filter:searchText | orderBy:'start'">
                                                        <div ng-if="row.start.getFullYear() == currentDate.getFullYear() && row.start.getMonth() >= currentDate.getMonth() && row.start.getDate() >= currentDate.getDate()">
                                                            <li>
                                                                <h4 style="cursor: pointer;"><b>Nome: {{row.title}}</b></h4>
                                                                <h5 style="cursor: pointer;">Início: {{row.start | date:'dd/MM/yyyy HH:mm'}}</h5>
                                                                <h5 style="cursor: pointer;">Fim: {{row.end | date:'dd/MM/yyyy HH:mm'}}</h5>
                                                                <hr>
                                                            </li>
                                                        </div> 
                                                    </div>
                                                </ul>
                                            </div>
                                            
                                        </div>
                                        
                                        <div class="col-md-8">
                                            <center>
                                                <div id="calendar" class="fc fc-unthemed fc-ltr" style="height: auto; width: auto; max-width: 85%;"></div>
                                            </center>
                                        </div>
                                        
                                    </div>
                                
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="footer" style="background-color: white;">
                    <div class="container-fluid clearfix">
                        <span class="float-none float-sm-right d-block mt-1 mt-sm-0 text-center">Desenvolvido por <strong>Danilo Ferreira Adorno</strong></span>
                    </div>
                </div>
                
            </div>
        </div>
    </div>
</div>  
    
<script type="text/javascript">
    var app = angular.module('app', []);
    app.controller('mController', function($scope, $document, $http, $timeout, $interval, $timeout){
        
        $scope.server = window.location.href.substring(0, window.location.href.indexOf("/mge"));
        //$scope.codUsuLogado = <%=request.getAttribute("userID")%>;
        $scope.isLoading = false;
        $scope.data = [];
        $scope.currentDate = new Date();
        
        //Preloader
        var preloader = new $.materialPreloader({
            position: 'top',
            height: '4px',
            col_1: '#464de4',
            col_2: '#007bff',
            col_3: '#28a745',
            col_4: '#f44336',
            fadeIn: 200,
            fadeOut: 200
        });

        //Consultas SNK
        function getData(){
            return new Promise(function(resolve,reject) {
                //Consulta SNK
                var arr = "";
                var query = " Select ";
                query += " Rownum As Id,Nussca, ";
                query += " fmt.hora(a.hrini)||'~'||fmt.hora(a.hrfin)||' - '||";
                query += " S.Nomesala||' - '||ad_get.nomeusu(a.codususol,'resumido') as NomeSala, ";
                query += " Nvl(C.Diatodo,'N') As Diatodo, ";
                query += " Extract(Day From A.Dtreserva) Dia, ";
                query += " Extract(Month From A.Dtreserva) As Mes, ";
                query += " Extract(Year From A.Dtreserva) As Ano, ";
                query += " Substr(Lpad(A.Hrini,4,0),0,2) As Hrini, ";
                query += " Substr(Lpad(A.Hrini,4,0),3,4) As Minini, ";
                query += " Substr(Lpad(A.Hrfin,4,0),0,2) As Hrfin, ";
                query += " Substr(Lpad(A.Hrfin,4,0),3,4) As Minfin ";
                query += " From Ad_Tsfssca A ";
                query += " Join Ad_Prhsalas S On A.Codsala = S.Codsala ";
                query += " left Join Ad_Tsfsscc C On C.Nussc = A.Nussc ";
                query += " Where Trunc(A.Dtreserva) >= Trunc(Sysdate-30) ";
                /*query += " And S.Nuprh = Nvl(${P_NUPRH},S.Nuprh) ";*/
                query += " And A.codsala = ${P_NUPRH} ";
                query += " And A.Status In ('A', 'P') ";

                executeQuery(query, arr, function(value) {
                    
                    $scope.data = [];
                    
                    var dados = JSON.parse(value);
                    if (dados.length > 0) {
                        var colunasTabela = Object.keys(dados[0]);
                        for (var k in dados) {
                            var diaTodo = dados[k]["DIATODO"] = "S" ? true : false;
                            $scope.data.push({
                                id: dados[k]["NUSSCA"],
                                title: dados[k]["NOMESALA"],
                                start: new Date(dados[k]["ANO"], dados[k]["MES"]-1, dados[k]["DIA"], dados[k]["HRINI"], dados[k]["MININI"]),
                                end: new Date(dados[k]["ANO"], dados[k]["MES"]-1, dados[k]["DIA"], dados[k]["HRFIN"], dados[k]["MINFIN"]),
                                allDay: diaTodo
                            });
                        }

                    }

                    resolve('Sucess');

                }, function(value) {
                    alert(value);
                    reject('Error');
                }); 

            });
        }
        
        function loadCalendar(){
            
          var calendarEl = document.getElementById('calendar');

          var calendar = new FullCalendar.Calendar(calendarEl, {
            locale: 'pt-br',
            plugins: [ 'dayGrid', 'timeGrid', 'list', 'bootstrap' ],
            defaultView: 'dayGridMonth',
            //timeZone: 'UTC',
            themeSystem: 'bootstrap',
            header: {
              left: 'title',
              right: 'dayGridMonth,timeGridWeek,timeGridDay,listMonth,prev,next'
            },
            buttonText: {
                today: 'Hoje',
                month: 'Mês',
                week: 'Semana',
                day: 'Dia'
            },  
            //weekNumberTitle: 'S',
            //editable: true,
            
            eventColor: "#464de4",  
            viewRender: function(){
                $('#preloader').hide();
            },
            eventClick: function(info) {
                abrirAgendamento(info.event.id);
            },  
            events: $scope.data, 
            
              
            eventRender: function (info) {
              $(info.el).tooltip({ title: info.event.title });     
            }
              
           
              
              
          });

          calendar.render();
        }
        
        function abrirAgendamento(Nussca){
			openApp("br.com.sankhya.menu.adicional.AD_TSFSSCA", {NUSSCA: Nussca});
		}
        
        $scope.addReserva = function (){
			openApp("br.com.sankhya.menu.adicional.AD_TSFSSCA", {NUSSCA: 0});
		}
        
        function disableButtons() {
            //Botão de imprimir
            var chartConfigButton = window.parent.document.getElementsByClassName("gwt-Button chartConfigButton")[0];
            chartConfigButton.style.visibility = "hidden";
        }
        
        async function doInit(){
            await getData();
        }
        
        //onInit
        this.$onInit = function () {
            //Inicia preloader
            $scope.isLoading = true;
            preloader.on();

            disableButtons();

            doInit().then(function() { 
                console.log('Buscou todos os dados!'); 
                
                //Inicia o calendário
                loadCalendar();

                //Finaliza preloader
                $scope.isLoading = false;
                preloader.off();

                //Processa todos os observadores do escopo atual e seus filhos
                $scope.$digest();
            });

        }
        
        
    });
    
</script>    

</body>

</html>
