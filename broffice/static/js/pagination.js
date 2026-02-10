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
    this.filteredRows = [];
    this.filters = {};
    
    this.init();
  }
  
  init() {
    // 모든 행 저장
    this.allRows = Array.from(document.querySelectorAll(`${this.tableSelector} tr`));
    
    // 초기 검색 매칭 속성 설정
    this.allRows.forEach(row => {
      row.setAttribute('data-search-match', 'true');
      row.setAttribute('data-filtered', 'true');
    });
    
    this.filteredRows = [...this.allRows];
    
    if (this.allRows.length > 0) {
      this.updatePagination();
    }
  }
  
  /**
   * 페이징 업데이트
   */
  updatePagination() {
    // 필터된 행만 추출 (data-filtered 속성 기반)
    this.filteredRows = this.allRows.filter(row => row.getAttribute('data-filtered') === 'true');
    const totalItems = this.filteredRows.length;
    const totalPages = Math.ceil(totalItems / this.itemsPerPage);
    
    // 현재 페이지 조정
    if (this.currentPage > totalPages && totalPages > 0) {
      this.currentPage = totalPages;
    }
    if (this.currentPage < 1) {
      this.currentPage = 1;
    }
    
    // 모든 행 숨기기
    this.allRows.forEach(row => {
      row.style.display = 'none';
    });
    
    // 현재 페이지에 해당하는 필터된 행만 표시
    const startIndex = (this.currentPage - 1) * this.itemsPerPage;
    const endIndex = Math.min(startIndex + this.itemsPerPage, totalItems);
    
    for (let i = startIndex; i < endIndex; i++) {
      this.filteredRows[i].style.display = '';
    }
    
    // 페이징 정보 업데이트
    const start = totalItems > 0 ? startIndex + 1 : 0;
    const end = endIndex;
    
    const paginationEl = document.querySelector(this.paginationSelector);
    if (paginationEl) {
      const showingRangeEl = paginationEl.querySelector('#showingRange');
      const totalCountEl = paginationEl.querySelector('#totalCount');
      
      if (showingRangeEl) showingRangeEl.textContent = `${start}-${end}`;
      if (totalCountEl) totalCountEl.textContent = totalItems;
    }
    
    // 페이징 버튼 생성
    this.renderPaginationButtons(totalPages);
    
    // 페이징 표시/숨김
    if (paginationEl) {
      if (totalItems > this.itemsPerPage) {
        paginationEl.style.display = 'flex';
      } else if (totalItems > 0) {
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
      
      row.setAttribute('data-filtered', showRow ? 'true' : 'false');
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
      row.setAttribute('data-filtered', 'true');
    });
    this.updatePagination();
  }
}
