import { useEffect, useState } from 'react'
import DoubletickLogo from "./assets/DoubletickLogo.png"
import viteLogo from '/vite.svg'
import './App.css'
import CustomerList from './components/CustomerList';
import Header from './components/Header';
import SearchFilterBar from './components/SearchFilterBar';

function App() {
  const [searchInput, setSearchInput] = useState('')
  const [debouncedSearch, setDebouncedSearch] = useState('')

  useEffect(() => {
    const id = setTimeout(() => setDebouncedSearch(searchInput.trim()), 250)
    return () => clearTimeout(id)
  }, [searchInput])

  return (
    <>
        <div>
        </div>
        <Header />
        <SearchFilterBar onSearchChange={setSearchInput} value={searchInput} />
        <CustomerList searchQuery={debouncedSearch} />
      </>
  )
}

export default App
