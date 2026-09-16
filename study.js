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

loadData();