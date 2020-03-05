<!--Desenvolvido por Marcus Rangel-->
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

    <title>Quadro de funcionários</title>

    <!-- styles -->
    <link rel="stylesheet" href="${BASE_FOLDER}/css/bootstrap.css">
    <link rel="stylesheet" href="${BASE_FOLDER}/css/style.css">
    <link rel="stylesheet" href="${BASE_FOLDER}/font-awesome/css/font-awesome.css">
    <link rel="stylesheet" href="${BASE_FOLDER}/css/ag-grid.css">
    <link rel="stylesheet" href="${BASE_FOLDER}/css/ag-theme-material.css">
    <link rel="stylesheet" href="${BASE_FOLDER}/css/normalize.css">
    <link rel="stylesheet" href="${BASE_FOLDER}/css/materialdesignicons/materialdesignicons.min.css">
    <link rel="stylesheet" href="${BASE_FOLDER}/css/materialPreloader.min.css">

    <!-- scrips -->
    <script src="${BASE_FOLDER}/js/angular.js"></script>
    <script src="${BASE_FOLDER}/js/jquery-3.4.1.js"></script>
    <script src="${BASE_FOLDER}/js/bootstrap.js"></script>
    <script src="${BASE_FOLDER}/js/ag-grid-enterprise.js"></script>
    <script src="${BASE_FOLDER}/js/date.format.js"></script>
    <script src="${BASE_FOLDER}/js/Chart.js"></script>
    <script src="${BASE_FOLDER}/js/angular-chart.js"></script>
    <script src="${BASE_FOLDER}/js/chartjs-plugin-datalabels.min.js"></script>
    <script src="${BASE_FOLDER}/js/materialPreloader.min.js"></script>
    
    
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
                                <div class="card">
                                    <div class="card-body">
                                        
                                        <h4 class="card-title"><i class="mdi mdi-finance" style="padding-right: 8px;"></i>Quadro de funcionários</h4>
                                    
                                        <div class="panel-body">
                                            <div id="mGrid1" class="ag-theme-material fullDivContent"></div>
                                        </div>

                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script type="text/javascript">
        
        var app = angular.module('app', []);
        
        app.controller('mController', function($scope, $document, $http){

            //Preloader
            var preloader = new $.materialPreloader({
                position: 'top',
                height: '6px',
                col_1: '#ffc107',
                col_2: '#007bff',
                col_3: '#28a745',
                col_4: '#f44336',
                fadeIn: 200,
                fadeOut: 200
            });
            
            var listaTable = [];
            
            var gridOptions = null;
            
            //Consultas SNK
            function getData(){
                return new Promise(function(resolve,reject) {
                    //Consulta SNK
                    var arr = "";
                    var query = `
                        select nvl1, nvl2, nvl3, nvl4, grau, numet, codlot, ideal, ativos, efetivos, afastados, faltas, vagas, dif
                        from table(ad_pkg_qdf.retorna_quadro)
                    `;
                    
                    executeQuery(query, arr, function(value) {
                        var dados = JSON.parse(value);
                        listaTable = [];
                        if (dados.length > 0) {
                            for (var k in dados) {
                                
                                var descrlot = [];
                                if( Number(dados[k].GRAU) == 1 ){
                                   descrlot = [dados[k].NVL1];
                                }
                                else if (Number(dados[k].GRAU) == 2){
                                    descrlot = [dados[k].NVL1, dados[k].NVL2];
                                }
                                else if (Number(dados[k].GRAU) == 3){
                                    descrlot = [dados[k].NVL1, dados[k].NVL2, dados[k].NVL3];
                                }
                                else if (Number(dados[k].GRAU) == 4){
                                    descrlot = [dados[k].NVL1, dados[k].NVL2, dados[k].NVL3, dados[k].NVL4];
                                }
                               
                                //Volume de Vendas
                                listaTable.push({
                                    coluna1: descrlot,
                                    coluna2: Number(dados[k]["IDEAL"]),
                                    coluna3: Number(dados[k]["ATIVOS"]),
                                    coluna4: Number(dados[k]["EFETIVOS"]), 
                                    coluna5: Number(dados[k]["AFASTADOS"]),
                                    coluna6: Number(dados[k]["FALTAS"]),
                                    coluna7: Number(dados[k]["VAGAS"]),
                                    coluna8: Number(dados[k]["DIF"])
                                });
                             
                                /*console.log({
                                    coluna1: descrlot,
                                    coluna2: Number(dados[k]["IDEAL"]),
                                    coluna3: Number(dados[k]["ATIVOS"]),
                                    coluna4: Number(dados[k]["AFASTADOS"]),
                                    coluna5: Number(dados[k]["EFETIVOS"]),
                                    coluna6: Number(dados[k]["FALTAS"]),
                                    coluna7: Number(dados[k]["DIF"])
                                } );*/
                                
                            }
                        }
                        
                        
                        
                        resolve('Sucess');

                    }, function(value) {
                        alert(value);
                        reject('Error');
                    }); 
                    
                });
            }
            
            //Compomentes
            function loadTable() {
                if (gridOptions == null){
                    //Colunas
                    var columnDefs = [
                        /*{
                            headerName: "Descrição da Meta",
                            field: "coluna1",
                            //sortable: true,
                            //filter: true,
                            //rowGroup: true,
                            //pivot: true,
                            //enablePivot: true,
                            //headerCheckboxSelection: true,
                            //headerCheckboxSelectionFilteredOnly: true,
                            //checkboxSelection: true,
                            //rowDrag: true,
                            //width: 500,
                            //cellRenderer: 'agGroupCellRenderer'
                        },*/
                        {
                            headerName: "Ideal",
                            field: "coluna2",
                            aggFunc: 'sum',
                            cellStyle: {'justify-content': 'center'},
                            cellRenderer: function(params) {
                                return "<span>" + formataNumero(params.value) + "</span>";
                            }
                        },
                        {
                            headerName: "Ativos",
                            field: "coluna3",
                            aggFunc: 'sum',
                            cellStyle: {'justify-content': 'center'},
                            cellRenderer: function(params) {
                                return "<span>" + formataNumero(params.value) + "</span>";
                            }
                        },
                        {
                            headerName: "Efetivos",
                            field: "coluna4",
                            aggFunc: 'sum',
                            cellStyle: {'justify-content': 'center'},
                            cellRenderer: function(params) {
                                return "<span>" + formataNumero(params.value) + "</span>";
                            }
                        },
                        {
                            headerName: "Afastados",
                            field: "coluna5",
                            aggFunc: 'sum',
                            cellStyle: {'justify-content': 'center'},
                            cellRenderer: function(params) {
                                return "<span>" + formataNumero(params.value) + "</span>";
                            }
                        },
                        {
                            headerName: "Faltas",
                            field: "coluna6",
                            aggFunc: 'sum',
                            cellStyle: {'justify-content': 'center'},
                            cellRenderer: function(params) {
                                return "<span>" + formataNumero(params.value) + "</span>";
                            }
                        },
                        {
                            headerName: "Vagas",
                            field: "coluna7",
                            aggFunc: 'sum',
                            cellStyle: {'justify-content': 'center'},
                            cellRenderer: function(params) {
                                return "<span>" + formataNumero(params.value) + "</span>";
                            }
                        },                        
                        {
                            headerName: "Dif",
                            field: "coluna8",
                            cellStyle: {'justify-content': 'center'},
                            cellRenderer: function(params) {
                                var valor;
                                
                                if(params.value < 0){
                                    valor = "text-danger";
                                } else if (params.value > 0 && params.value <= 10){
                                    valor = "text-warning";
                                } else {
                                    valor = "text-info";
                                }
                                
                                return "<span class="+valor+">" + formataNumero(params.value) + "</span>";
                            }
                        }
                    ];
                    
                    //Opções
                    gridOptions = setAgGridOptions(columnDefs);

                    var mGrid = document.querySelector('#mGrid1'); 

                    //Cria o grid
                    new agGrid.Grid(mGrid, gridOptions);
                    
                    //Fecha painel
                    gridOptions.api.closeToolPanel();
                    
                    //Tamanho automático para as colunas
                    gridOptions.api.sizeColumnsToFit(); 
                    
                    //Envia dados para ag-grid
                    gridOptions.api.setRowData(listaTable);
                    
                    
                } else {
                    //Fecha painel
                    gridOptions.api.closeToolPanel();
                    
                    //Tamanho automático para as colunas
                    gridOptions.api.sizeColumnsToFit(); 
                    
                    //Envia dados para ag-grid
                    gridOptions.api.setRowData(listaTable);
                }
            }
            
            //Outros métodos
            function setAgGridOptions(columnDefs) {
               //Licença de testes
                agGrid.LicenseManager.setLicenseKey("Evaluation_License-_Not_For_Production_Valid_Until_29_June_2019__MTU2MTc2MjgwMDAwMA==c738ebf60651ce2072b42bfd7813dbb6");
                
                //Opções
                return {
                    defaultColDef: { //Padrão para todas colunas
                        sortable: true,
                        resizable: true,
                        //filter: true,
                        //suppressMenu: true,
                        suppressSorting: true,
                        //sort: 'desc'
                        //pivot: true,
                        //enablePivot: true,
                        //sortable: true,
                        //filter: true,
                        //rowGroup: true,
                        //pivot: true,
                        //headerCheckboxSelection: true,
                        //headerCheckboxSelectionFilteredOnly: true,
                        //checkboxSelection: true,
                        //rowDrag: true,
                        //width: 100,
                        //autoHeight: true,
                    },
                    onGridReady: function (params) {
                        //params.api.closeToolPanel();
                        params.api.sizeColumnsToFit();
                    },
                    onGridSizeChanged: function (params) {
                        params.api.sizeColumnsToFit();
                        params.api.closeToolPanel();
                    },
                    columnDefs: columnDefs,
                    rowData: null,
                    sideBar: false, //Habilita painel lateral
                    treeData: true,
                    getDataPath: function(data) {
                        return data.coluna1;
                    },
                    autoGroupColumnDef: {
                        headerName: "Lotação",
                        width: 500,
                        suppressSizeToFit: true,
                        cellRendererParams: {
                            suppressCount: true,
                        }
                    },
                    /*getRowHeight: function (params) {
                        if (params.node && params.node.detail) {
                            var offset = 80;
                            var allDetailRowHeight = params.data.itemDetails.length * 60;
                            return allDetailRowHeight + offset;
                        } else {
                            // otherwise return fixed master row height
                            return 60;
                        }
                    },*/
                    //groupIncludeFooter: true,
                    groupIncludeTotalFooter: true,
                    defaultExportParams: {
                        //columnKeys: ['coluna1', 'coluna2','coluna3', 'coluna4', 'coluna5', 'coluna6'],
                        //allColumns: false,
                        //skipHeader: false,
                        //columnGroups: true,
                        //skipFooters: false,
                        //skipGroups: false,
                        //skipPinnedTop: false,
                        //skipPinnedBottom: false,
                        //allColumns: true,
                        //onlySelected: false,
                        fileName: "Quadro de funcionários",
                        sheetName: "Metas",
                        //exportMode: "xlsx",
                        //customHeader: 'Acompanhamento de metas' + '\n',
                        //customFooter: '\n \n Total  \n'
                    },
                    //masterDetail: true,
                    animateRows: true,
                    //sortingOrder: ['desc','asc',null],
                    //rowSelection: 'single',
                    //enableSorting: true,
                    //pagination: true,
                    //paginationPageSize: 7,
                    //showToolPanel: true,
                    //floatingFilter: true,
                    //suppressRowClickSelection: true,
                    //autoGroupColumnDef: autoGroupColumnDef,
                    //groupSelectsChildren: true,
                    //pivotMode: true,
                    //rowGroupPanelShow: 'always',
                    //statusBar: {
                    //    items: [{
                    //        component: 'agAggregationComponent'
                    //    }]
                    //},
                    //rowDragManaged: true, //row dragging is not possible when doing pagination
                    //enableRangeSelection: true,
                    localeText: {
                        // for filter panel
                        page: 'Página',
                        more: 'Mais',
                        to: 'a',
                        of: 'de',
                        next: 'Próximo',
                        last: 'Anterior',
                        first: 'Primeiro',
                        previous: 'Anterior',
                        loadingOoo: 'Carregando...',

                        // for set filter
                        selectAll: 'Selecionar todos',
                        searchOoo: 'Buscar...',
                        blanks: 'Em Branco',

                        // for number filter and text filter
                        filterOoo: 'Filtrar...',
                        applyFilter: 'Aplicar filtro...',
                        equals: 'Igual',
                        notEqual: 'Diferente',

                        // for number filter
                        lessThan: 'Menor que',
                        greaterThan: 'Maior que',
                        lessThanOrEqual: 'Menor ou igual',
                        greaterThanOrEqual: 'Maior ou igual',
                        inRange: 'No intervalo',

                        // for text filter
                        contains: 'Contendo',
                        notContains: 'Não contendo',
                        startsWith: 'Começando com',
                        endsWith: 'Terminando com',

                        // filter conditions
                        andCondition: 'e',
                        orCondition: 'ou',

                        // the header of the default group column
                        group: 'Grupo',

                        // tool panel
                        columns: 'Colunas',
                        filters: 'Filtros',
                        rowGroupColumns: 'Colunas Pivot',
                        rowGroupColumnsEmptyMessage: 'Colunas para grupo',
                        valueColumns: 'Colunas para valores',
                        pivotMode: 'Modo Pivot',
                        groups: 'Grupos',
                        values: 'Valores',
                        pivots: 'Pivots',
                        valueColumnsEmptyMessage: 'Colunas para soma',
                        pivotColumnsEmptyMessage: 'Arraste aqui para Pivot',
                        toolPanelButton: 'Painel de ferramentas',

                        // other
                        noRowsToShow: 'Nenhuma linha',

                        // enterprise menu
                        pinColumn: 'Fixar coluna',
                        valueAggregation: 'Valores agregação',
                        autosizeThiscolumn: 'Tamanho autómatico',
                        autosizeAllColumns: 'Tamnho autómatico para todas colunas',
                        groupBy: 'Agrupar por',
                        ungroupBy: 'Não agrupar por',
                        resetColumns: 'Resetar padrão colunas',
                        expandAll: 'Expandir todos',
                        collapseAll: 'Contrair todos',
                        toolPanel: 'Ir para painel de ferramentas',
                        export: 'Exportar',
                        csvExport: 'Exportar (.csv)',
                        excelExport: 'Exportar (.xlsx)',
                        excelXmlExport: 'Exportar (.xml)',

                        // enterprise menu pinning
                        pinLeft: 'Fixar a esquerda &lt;&lt;',
                        pinRight: 'Fixar a direita &gt;&gt;',
                        noPin: 'Não fixar &lt;&gt;',

                        // enterprise menu aggregation and status bar
                        sum: 'Soma',
                        min: 'Mínimo',
                        max: 'Máximo',
                        none: 'Nenhum',
                        count: 'Contagem',
                        average: 'Média',

                        // standard menu
                        copy: 'Copiar',
                        copyWithHeaders: 'Copiar com cabeçalhos',
                        ctrlC: 'Ctrl+C',
                        paste: 'Colar',
                        ctrlV: 'Ctrl+V'
                    },
                }; 
            }
            
            function formataMoeda(value){
                return new Intl.NumberFormat('pt-BR', {
                    style: 'currency',
                    currency: 'BRL'
                }).format(value);
            }
                    
            function formataNumero (value){
                var newValue =  new Intl.NumberFormat('pt-BR', {
                    minimumFractionDigits: 0
                }).format(value);
                
                
                if (newValue == "NaN"){
                    return new Intl.NumberFormat('pt-BR', {
                        minimumFractionDigits: 2
                    }).format(0.0);
                } else {
                    return newValue;
                }
            }
            
            async function doInit(){
                await getData();
            }
            
            //onInit
            this.$onInit = function () {
                //Inicia preloader
                preloader.on();
                
                doInit().then(function() { 
                    console.log('Buscou todos os dados!'); 
                    
                    //Inicia tab
                    loadTable();
                    
                    //Finaliza preloader
                    preloader.off();
                    
                    //Processa todos os observadores do escopo atual e seus filhos
                    $scope.$digest();
                    
                });
                
            }

        });
            
    </script>
    
</body>

</html>
