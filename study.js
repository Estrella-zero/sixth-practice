const state = { data: null };

const loadData = async () => {
  $('#status').text('加载中...').show();
  try {
    const response = await fetch('data/studyroom.json');
    if (!response.ok) {
      throw new Error('HTTP ' + response.status);
    }
    const data = await response.json();
    if (data.rooms.length === 0) {
      $('#status').text('暂无数据').show();
      return;
    }
    state.data = data;
    $('#sub-title').text(data.title + ' · 数据来源：课程统一数据集');
    $('#status').hide();
    renderCards(data);
    renderBarChart(data);
    renderLineChart(data);
    renderPieChart(data);
  } catch (error) {
    $('#status').text('加载失败：' + error.message).show();
  }
};

const renderCards = (data) => {
  data.rooms.forEach(r => {
    const free = r.seats- r.occupied;
    const rate =Math.round(r.occupied/r.seats*100);
    $('#cards').append(`
      <div class="col-md-4">
        <div class="card">
          <div class="card-body">
            <h3 class="card-title h6">${r.name}</h3>
            <p class="card-text fs-4">${r.occupied}<span class="fs-6 text-muted"> / ${r.seats} 座</span></p>
            <p class="card-text small text-muted">剩余${free}的座位</p>
          </div>
        </div>
      </div>
    `);
  });
};


let barChart = null;

const renderBarChart = (data) => {
  if (barChart === null) {
    barChart = echarts.init(document.querySelector('#bar-chart'));
  }
  barChart.setOption({
    title: { text: '各自习室座位与在座人数', left: 'center' },
    tooltip: { trigger: 'axis' },
    legend: { bottom: 0 },
    grid : { bottom: 90 },
    xAxis: { 
      type:'category',
      data:data.rooms.map(r =>r.name),
      axisLabel : { rotate:40, fontSize:10 }
    },
    yAxis: { name: '座' },
    series: [{
      name: '总座数',
      type: 'bar',
      data:data.rooms.map(r=>r.seats)
    },
    {
      name :'已坐座位数',
      type : 'bar' , 
      data : data.rooms.map( r =>r.occupied) 
    }]
  });
};

let lineChart = null;
const renderLineChart = (data)=> {
  if (lineChart !== null ) {
    lineChart. destroy ();
  } 
const labels = data.rooms.map( r => r. name );
  lineChart = new Chart( document.querySelector( '#line-chart' ), { 
    type :'line',
    data:{
      labels:labels,
      datasets : [
        { label : '使用率%' ,
          data : data. rooms . map ( r => Math . round (r. occupied / r. seats * 100 )), 
          borderWidth : 1 },
        { label : '空余座位' , 
          data : data. rooms . map ( r => r. seats - r. occupied ), 
          borderWidth : 1 }
      ]
    }, 
    options:{ 
      responsive:true , 
      maintainAspectRatio:false , 
      plugins:{ 
        title:{ display:true,text:'各自习室使用率与空余座位'} }
    }
  });
};

let pieChart = null;

const renderPieChart = (data) => { 
  if (pieChart === null ) {
    pieChart = echarts.init(document.querySelector('#pie-chart'));
  } 
  const byBuilding = {};
  data.rooms.forEach( r => {
    byBuilding[r.building] = (byBuilding[r. building ] || 0 ) + r.seats ;
  });
  pieChart. setOption ({ 
    title:{ text:'各楼馆座位占比' , left:'center' }, 
    tooltip:{ trigger:'item' ,formatter:'{b}:{c}座({d}%)'}, 
    legend:{ bottom:0}, 
    series:[{
      type:'pie',
      radius: '60%', 
      data:Object.keys(byBuilding).map ( k => ({ 
        name:k, 
        value:byBuilding[k] }))
    }]
  });
};

window.addEventListener('resize', () => {
  if (barChart) barChart.resize();
});

$('#cards').on('click', '.card', function () {    
  $(this).toggleClass('border-primary shadow');
});

$('#btn-all').on('click', () => {
  $('#cards .card').show();
});

$('#btn-open').on('click', () => {
  $('#cards .card').each(function () {
    $(this).toggle($(this).find('.status-tag').text() === '开放');
  });
});

$('#btn-free').on('click', () => {
  state.data.rooms.forEach((r, i) => {
    $('#cards .card').eq(i).toggle(r.seats - r.occupied > 0);
  });
});

loadData();