/**
 * 클라이언트 사이드 페이징 유틸리티
 * 테이블 데이터를 페이지 단위로 나눠서 표시
 */

class TablePagination {
  constructor(options = {}) {
    this.tableSelector = options.tableSelector || '.users-table tbody';
    this.paginationSelector = options.paginationSelector || '#usersPagination';
    this.itemsPerPage = options.itemsPerPage || 10;
    this.customFilter = options.customFilter || null;
    this.currentPage = 1;
    this.allRows = [];
    this.filters = {};
    
    this.init();
  }
  
  init() {
    // 모든 행 저장
    this.allRows = Array.from(document.querySelectorAll(`${this.tableSelector} tr`));
    
    // 초기 검색 매칭 속성 설정
    this.allRows.forEach(row => {
      row.setAttribute('data-search-match', 'true');
    });
    
    if (this.allRows.length > 0) {
      this.updatePagination();
    }
  }
  
  /**
   * 페이징 업데이트
   */
  updatePagination() {
    const visibleRows = this.allRows.filter(row => row.style.display !== 'none');
    const totalPages = Math.ceil(visibleRows.length / this.itemsPerPage);
    
    // 현재 페이지 조정
    if (this.currentPage > totalPages && totalPages > 0) {
      this.currentPage = totalPages;
    }
    if (this.currentPage < 1) {
      this.currentPage = 1;
    }
    
    // 페이지에 맞는 행만 표시
    visibleRows.forEach((row, index) => {
      const page = Math.floor(index / this.itemsPerPage) + 1;
      if (page === this.currentPage) {
        row.style.display = '';
      } else {
        row.style.display = 'none';
      }
    });
    
    // 페이징 정보 업데이트
    const start = (this.currentPage - 1) * this.itemsPerPage + 1;
    const end = Math.min(this.currentPage * this.itemsPerPage, visibleRows.length);
    
    const showingRangeEl = document.getElementById('showingRange');
    const totalCountEl = document.getElementById('totalCount');
    
    if (showingRangeEl) showingRangeEl.textContent = `${start}-${end}`;
    if (totalCountEl) totalCountEl.textContent = visibleRows.length;
    
    // 페이징 버튼 생성
    this.renderPaginationButtons(totalPages);
    
    // 페이징 표시/숨김
    const paginationEl = document.querySelector(this.paginationSelector);
    if (paginationEl) {
      if (visibleRows.length > this.itemsPerPage) {
        paginationEl.style.display = 'flex';
      } else if (visibleRows.length > 0) {
        paginationEl.style.display = 'flex';
        const paginationList = paginationEl.querySelector('.pagination');
        if (paginationList) paginationList.innerHTML = '';
      } else {
        paginationEl.style.display = 'none';
      }
    }
  }
  
  /**
   * 페이징 버튼 렌더링
   */
  renderPaginationButtons(totalPages) {
    const paginationEl = document.querySelector(this.paginationSelector);
    if (!paginationEl) return;
    
    const paginationList = paginationEl.querySelector('.pagination');
    if (!paginationList) return;
    
    paginationList.innerHTML = '';
    
    // 이전 버튼
    const prevLi = document.createElement('li');
    prevLi.className = `page-item ${this.currentPage === 1 ? 'disabled' : ''}`;
    prevLi.innerHTML = `<a class="page-link" href="#"><i class="ph ph-caret-left"></i></a>`;
    if (this.currentPage > 1) {
      prevLi.querySelector('a').addEventListener('click', (e) => {
        e.preventDefault();
        this.currentPage--;
        this.updatePagination();
      });
    }
    paginationList.appendChild(prevLi);
    
    // 페이지 번호 버튼 (최대 7개만 표시)
    const maxButtons = 7;
    let startPage = Math.max(1, this.currentPage - Math.floor(maxButtons / 2));
    let endPage = Math.min(totalPages, startPage + maxButtons - 1);
    
    if (endPage - startPage < maxButtons - 1) {
      startPage = Math.max(1, endPage - maxButtons + 1);
    }
    
    for (let i = startPage; i <= endPage; i++) {
      const li = document.createElement('li');
      li.className = `page-item ${i === this.currentPage ? 'active' : ''}`;
      li.innerHTML = `<a class="page-link" href="#">${i}</a>`;
      li.querySelector('a').addEventListener('click', (e) => {
        e.preventDefault();
        this.currentPage = i;
        this.updatePagination();
      });
      paginationList.appendChild(li);
    }
    
    // 다음 버튼
    const nextLi = document.createElement('li');
    nextLi.className = `page-item ${this.currentPage === totalPages ? 'disabled' : ''}`;
    nextLi.innerHTML = `<a class="page-link" href="#"><i class="ph ph-caret-right"></i></a>`;
    if (this.currentPage < totalPages) {
      nextLi.querySelector('a').addEventListener('click', (e) => {
        e.preventDefault();
        this.currentPage++;
        this.updatePagination();
      });
    }
    paginationList.appendChild(nextLi);
  }
  
  /**
   * 검색 필터 적용
   */
  applySearchFilter(searchTerm, searchFields = ['.users-cell-name', '.users-cell-email']) {
    const term = searchTerm.toLowerCase();
    
    this.allRows.forEach(row => {
      let match = false;
      
      for (const selector of searchFields) {
        const element = row.querySelector(selector);
        if (element && element.textContent.toLowerCase().includes(term)) {
          match = true;
          break;
        }
      }
      
      row.setAttribute('data-search-match', match ? 'true' : 'false');
    });
    
    this.currentPage = 1;
    this.applyAllFilters();
  }
  
  /**
   * 커스텀 필터 설정
   */
  setFilter(filterName, filterValue) {
    this.filters[filterName] = filterValue;
    this.currentPage = 1;
    this.applyAllFilters();
  }
  
  /**
   * 모든 필터 적용 (오버라이드 가능)
   */
  applyAllFilters() {
    this.allRows.forEach(row => {
      let showRow = true;
      
      // 검색 필터
      if (row.getAttribute('data-search-match') === 'false') {
        showRow = false;
      }
      
      // 커스텀 필터 적용 (하위 클래스에서 오버라이드)
      if (showRow && this.customFilter) {
        showRow = this.customFilter(row, this.filters);
      }
      
      row.style.display = showRow ? '' : 'none';
    });
    
    this.updatePagination();
  }
  
  /**
   * 페이지 리셋
   */
  reset() {
    this.currentPage = 1;
    this.filters = {};
    this.allRows.forEach(row => {
      row.setAttribute('data-search-match', 'true');
      row.style.display = '';
    });
    this.updatePagination();
  }
}
